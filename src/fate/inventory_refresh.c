extern short inventory_available[], inventory_primary_count[], inventory_secondary_count[];
extern long selected_inventory_slot;

void refresh_inventory(void)
{
    short slot;
    for (slot = 7; slot >= 0; --slot) {
        long available = inventory_available[slot];
        if (available != 1)
            continue;
        if (inventory_primary_count[slot] > 0 || inventory_secondary_count[slot] > 0) {
            selected_inventory_slot = slot;
            break;
        }
    }
    if ((int)slot == -1)
        selected_inventory_slot = 0;
}
