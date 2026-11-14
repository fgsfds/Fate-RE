BITS 32
ORG 0x1bfc

comspec:       db "COMSPEC", 0
cmd_exe:       db "CMD.EXE", 0
default_shell: db "COMMAND.COM", 0
cmd_name:      db "CMD", 0
command_name:  db "COMMAND", 0
current_directory_prefix: db ".\", 0
batch_extension:          db ".bat", 0
com_extension:            db ".com", 0
exe_extension:            db ".exe", 0
spawn_comspec:            db "COMSPEC", 0
spawn_cmd:                db "CMD", 0
spawn_command:            db "COMMAND", 0
