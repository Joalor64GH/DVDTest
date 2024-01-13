package;

import haxe.Exception;

#if windows
@:headerCode('
#include <Windows.h>
#include <string>
#include <iostream>

#define SCSI_IOCTL_DATA_OUT             0
#define SCSI_IOCTL_DATA_IN              1
#define SCSI_IOCTL_DATA_UNSPECIFIED     2

#define MAX_SENSE_LEN 18
#define IOCTL_SCSI_PASS_THROUGH_DIRECT  0x4D014

typedef unsigned short  USHORT;
typedef unsigned char   UCHAR;
typedef unsigned long   ULONG;
typedef void*           PVOID;
')

@:cppFileCode('
typedef struct _SCSI_PASS_THROUGH_DIRECT
{    
    USHORT Length;    
    UCHAR ScsiStatus;    
    UCHAR PathId;    
    UCHAR TargetId;
    UCHAR Lun;
    UCHAR CdbLength;    
    UCHAR SenseInfoLength;    
    UCHAR DataIn;    
    ULONG DataTransferLength;    
    ULONG TimeOutValue;    
    PVOID DataBuffer;    
    ULONG SenseInfoOffset;    
    UCHAR Cdb[16];
}
SCSI_PASS_THROUGH_DIRECT, *PSCSI_PASS_THROUGH_DIRECT;

typedef struct _SCSI_PASS_THROUGH_DIRECT_AND_SENSE_BUFFER 
{    
    SCSI_PASS_THROUGH_DIRECT sptd;    
    UCHAR SenseBuf[MAX_SENSE_LEN];
}
T_SPDT_SBUF;

')
#end

class DVDHandler
{
    #if windows
    private static inline var DVD_TRAY_CLOSED_NO_MEDIA:Int = 0;
    private static inline var DVD_TRAY_OPEN:Int = 1;
    private static inline var DVD_TRAY_CLOSED_MEDIA_PRESENT:Int = 2;
    private static inline var USB_DRIVE:Int = 3;
    
    @:functionCode('
    std::string GetDriveLetter(UINT driveType)
    {
        std::string driveLetter = "";
    
        DWORD drives = GetLogicalDrives();
        DWORD dwSize = MAX_PATH;
        char szLogicalDrives[MAX_PATH] = { 0 };
        DWORD dwResult = GetLogicalDriveStrings(dwSize, szLogicalDrives);
    
        if (dwResult > 0 && dwResult <= MAX_PATH)
        {
            char* szSingleDrive = szLogicalDrives;
    
            while (*szSingleDrive)
            {
                const UINT currentDriveType = GetDriveType(szSingleDrive);
    
                if (currentDriveType == driveType)
                {
                    driveLetter = szSingleDrive;
                    driveLetter = driveLetter.substr(0, 2);
                    break;
                }
    
                szSingleDrive += strlen(szSingleDrive) + 1;
            }
        } 
    
        return driveLetter;
    }
    ')
    public static function GetDvdDriveLetter():String { return GetDriveLetter(5); }
    public static function GetUsbDriveLetter():String { return GetDriveLetter(3); }
    
    @:functionCode('
    int GetDriveStatus(const std::string& drivePath)
    {   
        HANDLE hDevice;
        int iResult = -1;
        ULONG ulChanges = 0;  
        DWORD dwBytesReturned;  
        T_SPDT_SBUF sptd_sb;  
        byte DataBuf[8];   
        
        hDevice = CreateFile(drivePath.c_str(),
                            0,
                            FILE_SHARE_READ,
                            NULL,
                            OPEN_EXISTING,
                            FILE_ATTRIBUTE_READONLY,
                            NULL);   
        
        if (hDevice == INVALID_HANDLE_VALUE) return -1;          
        
        iResult = DeviceIoControl((HANDLE) hDevice,
                                  IOCTL_STORAGE_CHECK_VERIFY2,
                                  NULL,
                                  0,
                                  &ulChanges,
                                  sizeof(ULONG),
                                  &dwBytesReturned,
                                  NULL);  
        
        CloseHandle(hDevice);   
        
        if (iResult == 1) return DVD_TRAY_CLOSED_NO_MEDIA;   
        
        hDevice = CreateFile(drivePath.c_str(),
                             GENERIC_READ | GENERIC_WRITE,
                             FILE_SHARE_READ | FILE_SHARE_WRITE,
                             NULL,
                             OPEN_EXISTING,
                             FILE_ATTRIBUTE_READONLY,
                             NULL);
        
        if (hDevice == INVALID_HANDLE_VALUE) return -1;   
        
        sptd_sb.sptd.Length = sizeof(SCSI_PASS_THROUGH_DIRECT);  
        sptd_sb.sptd.PathId = 0;  
        sptd_sb.sptd.TargetId = 0;  
        sptd_sb.sptd.Lun = 0;  
        sptd_sb.sptd.CdbLength = 10;  
        sptd_sb.sptd.SenseInfoLength = MAX_SENSE_LEN;  
        sptd_sb.sptd.DataIn = SCSI_IOCTL_DATA_IN;  
        sptd_sb.sptd.DataTransferLength = sizeof(DataBuf);  
        sptd_sb.sptd.TimeOutValue = 2;  
        sptd_sb.sptd.DataBuffer = (PVOID) &(DataBuf);  
        sptd_sb.sptd.SenseInfoOffset = sizeof(SCSI_PASS_THROUGH_DIRECT);   
        sptd_sb.sptd.Cdb[0]  = 0x4a;  
        sptd_sb.sptd.Cdb[1]  = 1;  
        sptd_sb.sptd.Cdb[2]  = 0;  
        sptd_sb.sptd.Cdb[3]  = 0;  
        sptd_sb.sptd.Cdb[4]  = 0x10;  
        sptd_sb.sptd.Cdb[5]  = 0; 
        sptd_sb.sptd.Cdb[6]  = 0;  
        sptd_sb.sptd.Cdb[7]  = 0;  
        sptd_sb.sptd.Cdb[8]  = 8;  
        sptd_sb.sptd.Cdb[9]  = 0;  
        sptd_sb.sptd.Cdb[10] = 0; 
        sptd_sb.sptd.Cdb[11] = 0;  
        sptd_sb.sptd.Cdb[12] = 0;  
        sptd_sb.sptd.Cdb[13] = 0;  
        sptd_sb.sptd.Cdb[14] = 0;  
        sptd_sb.sptd.Cdb[15] = 0;   

        ZeroMemory(DataBuf, 8);
        ZeroMemory(sptd_sb.SenseBuf, MAX_SENSE_LEN);

        iResult = DeviceIoControl((HANDLE) hDevice,
                                  IOCTL_SCSI_PASS_THROUGH_DIRECT,
                                  (PVOID)&sptd_sb,
                                  (DWORD)sizeof(sptd_sb),
                                  (PVOID)&sptd_sb,
                                  (DWORD)sizeof(sptd_sb),
                                  &dwBytesReturned,
                                  NULL);
        
        CloseHandle(hDevice);   
        
        if(iResult)  
        {     
            if (DataBuf[5] == 0) iResult = DVD_TRAY_CLOSED_NO_MEDIA;
            else if (DataBuf[5] == 1) iResult = DVD_TRAY_OPEN;
            else iResult = DVD_TRAY_CLOSED_MEDIA_PRESENT;
        } 
    
        return iResult;
    }
    ')
    public static function GetDvdStatus():Int { return GetDriveStatus(GetDvdDriveLetter()); }
    public static function GetUsbDriveStatus():Int { return GetDriveStatus(GetUsbDriveLetter()); }

    @:functionCode('
    static function PrintDriveStatus(status:Int, driveType:Int):Void
    {
        switch (status)
        {
            case DVD_TRAY_CLOSED_NO_MEDIA:
                std::cout << (driveType == 5 ? "DVD" : "USB") << " tray closed, no media" << std::endl;
                break;
            case DVD_TRAY_OPEN:
                std::cout << (driveType == 5 ? "DVD" : "USB") << " tray open" << std::endl;
                break;
            case DVD_TRAY_CLOSED_MEDIA_PRESENT:
                std::cout << (driveType == 5 ? "DVD" : "USB") << " tray closed, media present" << std::endl;
                break;
            case USB_DRIVE:
                std::cout << "USB drive detected" << std::endl;
                break;
            default:
                std::cout << "Drive not ready" << std::endl;
                break;
        }
    }
    ')
    public static function main():Int
    {
        PrintDriveStatus(GetDvdStatus(), 5); // 5 represents DVD drive
        PrintDriveStatus(GetUsbDriveStatus(), 3); // 3 represents USB drive
        return 0;
    }
    #elseif mac
    trace('DVD detector is not available on MacOS');
    throw new Exception('DVD detector is not available on MacOS');
    #end
}
