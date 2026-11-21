"""Guard regressions for section placement, OMF transfers and retained tables."""
import unittest
from test_match_objects import record
from bind_main_menu_sections import bind_section, SECTIONS, FIXUPS, BRANCHES


def object_fixture(*, mutate=None, wrong_target=None, missing=None, public_offset=32):
    names = sorted({name for name, relative, addend, opcode in FIXUPS.values() if name})
    indices = {name: i+1 for i,name in enumerate(names)}
    code = bytearray(529)
    for site,(name,relative,addend,opcode) in FIXUPS.items():
        code[site:site+4] = addend.to_bytes(4,'little')
        if opcode: code[site-1:site] = opcode
    for site,(opcode,target,placed) in BRANCHES.items():
        width = 1 if len(opcode)==1 and opcode!=b'\xe9' else 4
        code[32+site:32+site+len(opcode)] = opcode
        code[32+site+len(opcode):32+site+len(opcode)+width] = (target-site-len(opcode)-width).to_bytes(width,'little',signed=True)
    if mutate: mutate(code)
    fixups=bytearray()
    for site,(name,relative,addend,opcode) in FIXUPS.items():
        if site==missing: continue
        target=indices[name] if name else 1
        if wrong_target and site==wrong_target[0]: target=indices[wrong_target[1]]
        fixups += bytes(((0xa4 if relative else 0xe4)|(site>>8),site&255,0x16 if name else 0x14,1,target))
    blob=record(0x96,b'\x05_TEXT\x04CODE\x04FLAT')
    blob+=record(0x99,b'\x69'+len(code).to_bytes(4,'little')+b'\x01\x02\x00')
    blob+=record(0x9a,b'\x03')
    blob+=record(0x8c,b''.join(bytes((len(n),))+n.encode()+b'\x00' for n in names))
    blob+=record(0xa1,b'\x01'+bytes(4)+code)
    name=b'dispatch_main_menu_'
    blob+=record(0x91,b'\x00\x01'+bytes((len(name),))+name+public_offset.to_bytes(4,'little')+b'\x00')
    return blob+record(0x9d,fixups)


class MainMenuSections(unittest.TestCase):
    def bind(self, blob, section=0):
        symbol,start,end,address=SECTIONS[section]
        pointers={}
        code,refs=bind_section(blob,symbol,address=address,code_bindings=pointers)
        return code,refs,pointers

    def test_links_real_destinations_and_excludes_private_table(self):
        obj=object_fixture()
        rows=[self.bind(obj,i) for i in range(3)]
        self.assertEqual([len(code) for code,refs,p in rows],[212,111,67])
        self.assertEqual([len(refs) for code,refs,p in rows],[12,3,6])
        self.assertEqual(rows[0][2],{0x51:0x2a128})
        self.assertEqual(rows[1][2],{})
        self.assertEqual(rows[2][2],{})
        code=rows[0][0]
        self.assertEqual(code[7:9],b'\x0f\x84')
        self.assertEqual(0x3a188+13+int.from_bytes(code[9:13],'little',signed=True),0x3a334)
        code=rows[1][0]
        self.assertEqual(code[0],0xe8)
        self.assertEqual(0x3a284+5+int.from_bytes(code[1:5],'little',signed=True),0x386d3)
        code=rows[2][0]
        self.assertEqual(code[-5],0xe9)
        self.assertEqual(0x3a345+int.from_bytes(code[-4:],'little',signed=True),0x3947f)

    def test_rejects_external_opcode_addend_and_semantic_target_changes(self):
        site=next(s for s,(name,relative,a,op) in FIXUPS.items() if name=='draw_menu_text_')
        for blob in (object_fixture(mutate=lambda c:c.__setitem__(site-1,0xe9)),
                     object_fixture(mutate=lambda c:c.__setitem__(site,1)),
                     object_fixture(wrong_target=(site,'nextpage_'))):
            with self.subTest(),self.assertRaises(ValueError): self.bind(blob)

    def test_rejects_changed_unlinked_resume_table_slots(self):
        for slot in (20,24):
            with self.subTest(slot=slot),self.assertRaisesRegex(ValueError,'fixup form'):
                self.bind(object_fixture(mutate=lambda c:c.__setitem__(slice(slot,slot+4),(462).to_bytes(4,'little'))))

    def test_rejects_branch_condition_and_source_destination_changes(self):
        for change in ((32+0x43+8,0x85),(32+0x43+9,0)):
            with self.subTest(change=change),self.assertRaisesRegex(ValueError,'Section branch'):
                self.bind(object_fixture(mutate=lambda c:c.__setitem__(*change)))

    def test_requires_complete_fixups_public_and_original_placement(self):
        for obj in (object_fixture(missing=0),object_fixture(public_offset=0)):
            with self.assertRaises(ValueError): self.bind(obj)
        with self.assertRaisesRegex(ValueError,'placement'):
            bind_section(object_fixture(),'main_menu_loop_',address=0x3a189,code_bindings={})
        with self.assertRaisesRegex(ValueError,'empty output'):
            bind_section(object_fixture(),'main_menu_loop_',address=0x3a188,code_bindings={0:1})

    def test_leaf_route_declines_loaded_and_alternate_bindings(self):
        from verify_c_leaf import bind_leaf_details
        obj=object_fixture()
        for values,functions,code in (({'_totalclock':0x307e88},{},{}),
                                      ({},{'confirm_menu_action_':0x12345},{}),
                                      ({},{},{'_totalclock':0x287e88})):
            with self.subTest(),self.assertRaisesRegex(ValueError,'fixed bindings'):
                bind_leaf_details(obj,'main_menu_loop_',values,address=0x3a188,
                                  functions=functions,absolute_code=code,code_bindings={})
