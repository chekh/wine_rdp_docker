//+------------------------------------------------------------------+
//
// Copyright (C) 2019 Nikolai Khramkov
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//+------------------------------------------------------------------+

// TODO: Deviation

#property copyright   "Copyright 2019, Nikolai Khramkov."
#property link        "https://github.com/khramkov"
#property version     "2.00"
#property description "MQL5 JSON API"
#property description "See github link for documentation"

#include <Trade/AccountInfo.mqh>
#include <Trade/DealInfo.mqh>
#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/OrderInfo.mqh>
#include <Zmq/Zmq.mqh>
#include <Json.mqh>
#include <StringToEnumInt.mqh>
#include <ControlErrors.mqh>

// Load MQL5-JSON-API includes
// Required:

#include <MQL5-JSON_API/AccountInfo.mqh>
#include <MQL5-JSON_API/Commands.mqh>
#include <MQL5-JSON_API/Configuration.mqh>
#include <MQL5-JSON_API/Helpers.mqh>
#include <MQL5-JSON_API/HistoryInfo.mqh>
#include <MQL5-JSON_API/StreamLiveData.mqh>
#include <MQL5-JSON_API/TimeFrames.mqh>
#include <MQL5-JSON_API/ZMQSocketFunctions.mqh>
#include <MQL5-JSON_API/Positions.mqh>
#include <MQL5-JSON_API/Orders.mqh>
#include <MQL5-JSON_API/TradesEvents.mqh>
#include <MQL5-JSON_API/Trader.mqh>
#include <MQL5-JSON_API/uuid.mqh>

// Set ports and host for ZeroMQ
string    HOST         = "*";
input int SYS_PORT     = 5555;
input int DATA_PORT    = 5556;
input int STREAM_PORT  = 5559;
input bool strict_mode = true;

// ZeroMQ Connections
Context context("MQL5 JSON API");
 
Socket sysSocket(context, ZMQ_REP);
Socket dataSocket(context, ZMQ_PUSH);
Socket streamSocket(context, ZMQ_PUB);


input string Inp_Expert_Title        = "JsonAPI";
input bool   debugLog                = true;
input int    BindingAttempts         = 5;
input int    BindingDelay            = 65;
input int    stateMillisecondsPeriod = 30 * 1000;
input int    retryDeal               = 10;

// Global variables
bool debug                 = debugLog;
bool liveStream            = true;
bool streamAccountInfo     = false;
bool streamBalanceInfoOnly = true;
bool connectedFlag         = true;
int  deInitReason          = -1;
int  statePeriodCounter    = 0;
bool justUpdatedPrice      = false;

// Variables for handling price data stream
struct SymbolSubscription
  {
   string            symbol;
   string            chartTf;
   datetime          lastBar;
   bool              stream;   
   bool              stream_acc_info;
  };
  
SymbolSubscription symbolSubscriptions[];
int symbolSubscriptionCount = 0;

// Error handling
ControlErrors mControl;
uint startTime;

ulong magicForPendingClose[];  // Array to store the magic numbers for pending position close
bool  started = false;  // flag of counter relevance

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  
    // Setting up error reporting
       mControl.SetAlert(false);
       mControl.SetSound(false);
       mControl.SetWriteFlag(false);

       /* Bindinig ZMQ ports on init */
    // Skip reloading of the EA script when the reason to reload is a chart timeframe change
       if(deInitReason != REASON_CHARTCHANGE){
          InitSockets();

          EventSetMillisecondTimer(1);

          int bindSocketsDelay = BindingDelay; // Seconds to wait if binding of sockets fails.
          int bindAttemtps = BindingAttempts;  // Number of binding attemtps

          for(int i=0; i<bindAttemtps; i++){
             Print("Binding sockets #", i, "...");
             if(BindSockets()){
                startTime = TimeCurrent();
                string startTimeString = TimeToString(startTime, TIME_DATE|TIME_SECONDS);
                Print("JsonAPI Expert initialized at ", startTimeString);
                started   = true;

                return(INIT_SUCCEEDED);
             }
             else{
                Print("Binding sockets #", i, " failed. Waiting ", bindSocketsDelay, " seconds to try again...");
                Sleep(bindSocketsDelay*1000);
             }
          }
       }

      Print("Binding of sockets failed permanently.");
      return(INIT_FAILED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   /* Unbinding ZMQ ports on denit */

// TODO Ports do not get freed immediately under Wine. How to properly close ports? There is a timeout of about 60 sec.
// https://forum.winehq.org/viewtopic.php?t=22758
// https://github.com/zeromq/cppzmq/issues/139

   deInitReason = reason;

// Skip reloading of the EA script when the reason to reload is a chart timeframe change
   if(reason != REASON_CHARTCHANGE)
     {
      Print(__FUNCTION__," Deinitialization reason: ", getUninitReasonText(reason));
      started = false;
      CloseSockets();
      UnBindSockets();
      
      // Shutdown ZeroMQ Context
      context.shutdown();
      context.destroy(0);

      // Reset
      CommandRequest empty_command;
      ResetSubscriptions(empty_command);

      EventKillTimer();
     }
  }

//+------------------------------------------------------------------+
//| Expert timer function                                            |
//+------------------------------------------------------------------+
void OnTimer()
  {

// Stream live price and Account info data
   StreamPriceData();
   StreamAccountInfo();

// Send state (heartbeat) to subscribers
   statePeriodCounter++;
   if (statePeriodCounter==stateMillisecondsPeriod){
      StateToSubscribers();
      statePeriodCounter = 0;
   }

// Get request from ZMQ and proceed it
   ZmqMsg request;

// Get request from client via System socket.
   sysSocket.recv(request, true);

// Request recived
   if(request.size()>0)
     {
      // Pull request to RequestHandler().
      RequestHandler(request);
     }
     
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
 {
    if(started) ClosePositionsByMagicList();
 }

//+------------------------------------------------------------------+
//| called when a Trade event arrives                                |
//+------------------------------------------------------------------+
void OnTrade()
  {
      
//     StreamPositionsOnTradeEvents();
  
  }
  
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {

     StreamTradeTransactionEvents(trans,request, result);

  }  
//+------------------------------------------------------------------+
