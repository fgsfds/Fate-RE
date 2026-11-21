import unittest
from unittest.mock import patch
from report_watcom_markers import placed_measurement
from verify_c_leaf import LEAF_CODE_SLICES, LEAF_ENTRY_PREFIXES


class PlacedMarkerMeasurements(unittest.TestCase):
    def test_native_slice_selects_and_rebases_only_its_branch_changes(self):
        with patch.dict(LEAF_CODE_SLICES, {'view': ('public', 2, 6, 8)}):
            result = placed_measurement('view', 4, (8, 0, [], [(1, 2, 6), (4, 2, 6)], 0))
            self.assertEqual(result, (4, 0, [], [(2, 2, 6)], 0))

    def test_slice_rejects_inline_ownership_instead_of_inventing_counts(self):
        with patch.dict(LEAF_CODE_SLICES, {'view': ('public', 2, 6, 8)}):
            for measurement in ((8, 1, [(2, 3)], [], 1), (8, 0, [], [], 1)):
                with self.subTest(measurement=measurement), self.assertRaisesRegex(
                        ValueError, 'Cannot attribute inline invocations'):
                    placed_measurement('view', 4, measurement)

    def test_slice_checks_full_public_and_inventory_extents(self):
        with patch.dict(LEAF_CODE_SLICES, {'view': ('public', 2, 6, 8)}):
            with self.assertRaisesRegex(ValueError, 'Compiler public extent'):
                placed_measurement('view', 4, (9, 0, [], [], 0))
            with self.assertRaisesRegex(ValueError, 'Inventory extent'):
                placed_measurement('view', 3, (8, 0, [], [], 0))

    def test_retained_prefix_still_rebases_and_rejects_hidden_markers(self):
        with patch.dict(LEAF_ENTRY_PREFIXES, {'view': 2}):
            self.assertEqual(placed_measurement('view', 6, (8, 1, [(3, 4)], [(5, 2, 6)], 1)),
                             (6, 1, [(1, 2)], [(3, 2, 6)], 1))
            with self.assertRaisesRegex(ValueError, 'retained prefix'):
                placed_measurement('view', 6, (8, 1, [(1, 2)], [], 1))


class UnlinkedTableContext(unittest.TestCase):
    def inventory(self, obj):
        from hashlib import sha256
        from bind_main_menu_sections import SECTIONS, bind_section
        rows=[]
        for symbol,start,end,address in SECTIONS:
            code,refs=bind_section(obj,symbol,address=address,code_bindings={})
            rows.append(dict(symbol=symbol,object='mainmenu.obj',raw_offset=hex(address+0x25600),
                             bytes=end-start,sha256=sha256(code).hexdigest(),le_pointers=len(refs)))
        return dict(spans=rows,non_routine_code_spans=[])

    def test_checks_private_table_without_adding_credited_table_bytes(self):
        from test_main_menu_sections import object_fixture
        from report_watcom_markers import verified_switch_tables
        obj=object_fixture(); inventory=self.inventory(obj)
        self.assertEqual(verified_switch_tables(inventory,'mainmenu.obj',obj),((1,0,32),))
        self.assertEqual(inventory['non_routine_code_spans'],[])
        self.assertEqual(sum(r['bytes'] for r in inventory['spans']),444)

    def test_rejects_incomplete_inventory_or_changed_linked_section(self):
        from test_main_menu_sections import object_fixture
        from report_watcom_markers import verified_switch_tables
        obj=object_fixture()
        inventory=self.inventory(obj);inventory['spans'].pop()
        with self.assertRaisesRegex(ValueError,'inventory differs'):
            verified_switch_tables(inventory,'mainmenu.obj',obj)
        inventory=self.inventory(obj);inventory['spans'][0]['sha256']='0'*64
        with self.assertRaisesRegex(ValueError,'linked section differs'):
            verified_switch_tables(inventory,'mainmenu.obj',obj)
