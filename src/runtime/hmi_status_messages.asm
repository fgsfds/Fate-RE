; HMI status messages and the matching table of DATA-relative pointers.
BITS 32
ORG 0x1c4a

%ifdef BUILD_STATUS_POINTERS
    %macro status_message 3
        dd %2
    %endmacro
%else
    dw 0
    %macro status_message 3
        db %3, 0
    %endmacro
%endif

status_message hmi_status_0, 0x1c4c, "Error Code Does Not Indicate An Error"
status_message hmi_status_1, 0x1c72, "Specified Driver Is Not Loaded"
status_message hmi_status_2, 0x1c91, "Specified Pointer Is NULL"
status_message hmi_status_3, 0x1cab, "Detection System Is Already Initialized"
status_message hmi_status_4, 0x1cd3, "File Open Failure"
status_message hmi_status_5, 0x1ce5, "Memory Allocation Failure"
status_message hmi_status_6, 0x1cff, "Invalid Driver ID"
status_message hmi_status_7, 0x1d11, "Driver Not Found"
status_message hmi_status_8, 0x1d22, "Detection System Failed To Find Hardware"
status_message hmi_status_9, 0x1d4b, "Driver Already Loaded Using Specified Handle"
status_message hmi_status_10, 0x1d78, "Invalid Handle"
status_message hmi_status_11, 0x1d87, "No Handles Available"
status_message hmi_status_12, 0x1d9c, "Hardware Already Paused"
status_message hmi_status_13, 0x1db4, "Hardware Not Paused"
status_message hmi_status_14, 0x1dc8, "Data Is Not Valid"
status_message hmi_status_15, 0x1dda, "HMI*.386 File Open Failure"
status_message hmi_status_16, 0x1df5, "Incorrect Port"
status_message hmi_status_17, 0x1e04, "Incorrect IRQ"
status_message hmi_status_18, 0x1e12, "Incorrect DMA"
status_message hmi_status_19, 0x1e20, "Incorrect DMA/IRQ"
status_message hmi_status_20, 0x1e32, "Stream Already Playing"
status_message hmi_status_21, 0x1e49, "Stream Empty"
status_message hmi_status_22, 0x1e56, "Stream Already Paused"
status_message hmi_status_23, 0x1e6c, "Stream Not Paused"

%ifndef BUILD_STATUS_POINTERS
    dw 0
%endif
