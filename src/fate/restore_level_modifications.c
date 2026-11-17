#include "levmods.h"

int restore_level_modifications(int slot)
{
    union { char text[80]; Prefix prefix; } command;
    char extension[8];
    int level;

    read_game_data(slot);
    format_command(extension, restore_extension, slot);

    for (level = 1; level <= 25; ++level) {
        if (level != (int)current_level && modified_levels[level]) {
            int result;
            const char *board;
            command.prefix = restore_copy_prefix;
            board = level_names[level];
            strcat(command.text, board);
            strcat(command.text, extension);
            strcat(command.text, restore_space);
            strcat(command.text, board);
            strcat(command.text, restore_mod_extension);
            strcat(command.text, restore_copy_options);
            result = system(command.text);
            if (result) {
                format_command(error_buffer, restore_copy_error, result);
                report_game_error(error_buffer);
            }
        }
    }
    return 0;
}
