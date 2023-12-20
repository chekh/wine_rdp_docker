//+------------------------------------------------------------------+
//|                                                 DealsHistory.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, RestAdviser Ltd."
#property link      "https://www.mql5.com"
#property version   "1.01"

#property script_show_inputs

input string InpFileName="jsonapi.set";
input string InpDirectoryName="";
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   ResetLastError();
   int file_handle=FileOpen(InpDirectoryName+"//"+InpFileName,FILE_READ|FILE_ANSI);
   if(file_handle!=INVALID_HANDLE)
     {
      PrintFormat("File %s is opened for reading",InpFileName);
      PrintFormat("File path: %s\\Files\\",TerminalInfoString(TERMINAL_DATA_PATH));
      int    str_size;
      string str;
      //---
      while(!FileIsEnding(file_handle))
        {
         str_size=FileReadInteger(file_handle,INT_VALUE);

         str=FileReadString(file_handle,str_size);
         SplitString(str);
         PrintFormat(str);
        }

      FileClose(file_handle);
      PrintFormat("Data read, File %s is closed.",InpFileName);
     }
   else
      PrintFormat("Couldn't read File %s, Error code = %d",InpFileName,GetLastError());
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SplitString(string to_split)
  {

   string sep="=";                  // ??????????? ? ???? ???????
   ushort u_sep;                    // ??? ??????? ???????????
   string result[];                 // ?????? ??? ????????? ?????

   u_sep=StringGetCharacter(sep,0);
   int k=StringSplit(to_split,u_sep,result);
   PrintFormat("Counted: %d. separator '%s' code %d",k,sep,u_sep);

   if(k>0)
     {
      for(int i=0; i<k; i++)
        {
         PrintFormat("result[%d]=\"%s\"",i,result[i]);
        }
     }

  }
//+------------------------------------------------------------------+
