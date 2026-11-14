/* Read-only strings referenced by the matched main and cleanup callback.
 * Symbol names and explicit CONST placement are reconstruction choices. */
#pragma data_seg("CONST", "DATA")
const char main_cleanup_message[] = "Video Mode Not Supported or Abnormal Exit.\n";
const char main_group_name[] = "stuff.dat";
const char main_load_error[] = "\nNot a valid Map name";
const char main_default_selection[] = "start";
