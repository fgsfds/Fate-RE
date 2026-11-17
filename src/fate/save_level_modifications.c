#include "levmods.h"

int save_level_modifications(int slot)
{
    union { char text[80]; Prefix prefix; } command;
    char extension[8];
    int level;

    format_command(extension, save_extension, slot);
    write_game_data(slot);

    for (level = 1; level <= 25; ++level) {
        if (level != (int)current_level && modified_levels[level]) {
            int result;
            const char *board;
            command.prefix = save_copy_prefix;
            board = level_names[level];
            strcat(command.text, board);
            strcat(command.text, save_mod_extension_and_space);
            strcat(command.text, board);
            strcat(command.text, extension);
            strcat(command.text, save_copy_options);
            result = system(command.text);
            if (result) {
                format_command(error_buffer, save_copy_error, result);
                report_game_error(error_buffer);
            }
        }
    }
    return 0;
}
