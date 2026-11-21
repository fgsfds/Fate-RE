"""Ensure omitted call/read contexts cannot silently change beneath exact prefixes."""
import unittest
from test_match_objects import record
from verify_c_leaf import bind_leaf_details, DATA_OFFSETS, FUNCTION_ADDRESSES


def context_object(select=False, *, mutate=None, wrong_call=False, missing=None):
    if select:
        public='main_menu_select_';code=bytearray(b'\x90'*29)
        fields={2:('_game_in_progress',False),11:('_main_menu_selection',False),
                19:('_main_menu_selection',False),24:('_menu_dispatch_active',False)}
        code[7:9]=b'\x74\x08';code[15:17]=b'\xeb\x06';code[23:]=b'\xa1'+bytes(4)+b'\xc3'
    else:
        public='main_caption_setup_';code=bytearray(b'\x90'*46)
        fields={2:('_loading_caption_columns',False),12:('_loading_caption',False),41:('draw_menu_text_',True)}
        code[40:]=b'\xe8'+bytes(4)+b'\xc3'
    names=sorted({name for name,relative in fields.values()}|{'nextpage_'})
    indices={name:i+1 for i,name in enumerate(names)}
    for off in fields:code[off:off+4]=bytes(4)
    if mutate:mutate(code)
    fixes=bytearray()
    for off,(name,relative) in fields.items():
        if off==missing:continue
        if wrong_call and relative:name='nextpage_'
        fixes+=bytes(((0xa4 if relative else 0xe4)|(off>>8),off&255,0x16,1,indices[name]))
    blob=record(0x96,b'\x05_TEXT\x04CODE\x04FLAT')
    blob+=record(0x99,b'\x69'+len(code).to_bytes(4,'little')+b'\x01\x02\x00')
    blob+=record(0x9a,b'\x03')
    blob+=record(0x8c,b''.join(bytes((len(n),))+n.encode()+b'\x00' for n in names))
    blob+=record(0xa1,b'\x01'+bytes(4)+code)
    p=public.encode();blob+=record(0x91,b'\x00\x01'+bytes((len(p),))+p+bytes(5))
    return blob+record(0x9d,fixes)


class PrivateContextFixups(unittest.TestCase):
    def bind(self,obj,select=False):
        return bind_leaf_details(obj,'main_menu_selection_' if select else 'main_menu_caption_',
                                 DATA_OFFSETS,address=0x3a171 if select else 0x3a25c,
                                 functions=FUNCTION_ADDRESSES,code_bindings={})

    def test_caption_excludes_validated_private_call_and_return(self):
        code,refs=self.bind(context_object())
        self.assertEqual(len(code),40)
        self.assertEqual(refs,{2:0x12df8,12:0xd7c})

    def test_rejects_changed_private_call_target_opcode_and_addend(self):
        for obj in (context_object(wrong_call=True),context_object(missing=41),
                    context_object(mutate=lambda c:c.__setitem__(40,0xe9)),
                    context_object(mutate=lambda c:c.__setitem__(41,1))):
            with self.subTest(),self.assertRaises(ValueError):self.bind(obj)

    def test_selection_keeps_both_original_short_branches(self):
        code,refs=self.bind(context_object(True),True)
        self.assertEqual(len(code),23)
        self.assertEqual(code[7:9],b'\x74\x08')
        self.assertEqual(code[15:17],b'\xeb\x06')
        self.assertEqual(refs,{2:0x772b8,11:0x1740ec,19:0x1740ec})

    def test_rejects_unlinked_active_read_changes_and_branch_target_changes(self):
        for obj in (context_object(True,missing=24),
                    context_object(True,mutate=lambda c:c.__setitem__(23,0xb8)),
                    context_object(True,mutate=lambda c:c.__setitem__(8,9))):
            with self.subTest(),self.assertRaises(ValueError):self.bind(obj,True)

    def test_direct_verifier_cli_exposes_all_menu_slices(self):
        import subprocess,sys
        from pathlib import Path
        script=Path(__file__).resolve().parents[1]/'verify_c_leaf.py'
        result=subprocess.run([sys.executable,str(script),'--help'],capture_output=True,text=True,check=True)
        for symbol in ('main_menu_loop_','main_menu_caption_','main_menu_selection_'):
            self.assertIn(symbol,result.stdout)
