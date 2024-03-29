//+------------------------------------------------------------------+
//|                                                     GuoJiaEa.mq4 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright (C) 2015-2020, Huatao X"
#property link      "tojoyccnu@163.com"
#property strict

#include <Mql/Lang/ExpertAdvisor.mqh>
#include <Mql/History/TimeSeriesData.mqh>
#include <Mql/History/PriceBreak.mqh>
#include <Mql/Trade/FxSymbol.mqh>
#include <Mql/Trade/Order.mqh>
#include <Mql/Trade/OrderGroup.mqh>
#include <Mql/Trade/OrderManager.mqh>
#include <Mql/Trade/OrderTracker.mqh>
#include <Mql/Charts/LabeledLine.mqh>
#include <Mql/UI/FreeFormElement.mqh>
#include <Mql/UI/ReadOnlyLabel.mqh>
#include <Mql/Utils/ParseUtils.mqh>

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
class GuoJiaEAParam: public AppParam
  {
  public:
   ObjectAttr(bool,EnableAlgorithm, EnableAlgorithm);                          // 算法交易
   ObjectAttr(int,MinAlgorithmValue,MinAlgorithmValue);                        // 最小算法交易值
   ObjectAttr(int,MaxAlgorithmValue,MaxAlgorithmValue);                        // 最大算法交易值
   ObjectAttr(bool,EnableListKLine,EnableListKLine);                           // 启动连续K线
   ObjectAttr(int,ListKLineValue, ListKLineValue);                             // 连续K线根数
   ObjectAttr(int,ListKLineRange, ListKLineRange);                             // 连续K线波幅
   ObjectAttr(bool,EnableRSI,EnableRSI);                                       // 启动RSI
   ObjectAttr(int,RSITimeFrame,RSITimeFrame);                                  // RSI周期
   ObjectAttr(double,RSIValueHigh, RSIValueHigh);                              // RSI高值
   ObjectAttr(double,RSIValueLow, RSIValueLow);                                // RSI低值
   ObjectAttr(bool,EnableMA,EnableMA);                                         // 启动MA
   ObjectAttr(int,MAValueShort, MAValueShort);                                 // 短均线
   ObjectAttr(int,MAValueLong, MAValueLong);                                   // 长均线
   ObjectAttr(bool,EnableMARangeTrend,EnableMARangeTrend);                     // 启动MA间距趋势
   ObjectAttr(bool, EnableOpenTimes, EnableOpenTimes);                         // 启动开仓时间控制
   ObjectAttr(bool, IsServerTime, IsServerTime);                               // false=本地时间 true=服务器时间
   ObjectAttr(string, OpenTimesRanges, OpenTimesRanges);                       // 允许开仓时间段
   ObjectAttr(bool, EnableMultipleTicket, EnableMultipleTicket);               // 开启多单模式
   ObjectAttr(double,BaseLotValue, BaseLotValue);                              // 初始下单手数
   ObjectAttr(bool, EnableBaseMinKLineNumSinceClosed, EnableBaseMinKLineNumSinceClosed); // 开启初始下单最小K线数
   ObjectAttr(int, BaseMinKLineNumSinceClosed, BaseMinKLineNumSinceClosed);    // 初始下单最小K线数(以最后平仓时间)
   ObjectAttr(string, BackLotValue, BackLotValue);                             // 逆势下单手数
   ObjectAttr(string, ForwardAddBuyRange, ForwardAddBuyRange);                 // 顺势加仓间距
   ObjectAttr(string, BackAddBuyRange, BackAddBuyRange);                       // 逆势加仓间距
   ObjectAttr(string, BackAddBuyRevertRange, BackAddBuyRevertRange);           // 逆势加仓回调点数
   ObjectAttr(string, ForwardCloseOrderRevertRange, ForwardCloseOrderRevertRange);// 顺势平仓回调点数
   ObjectAttr(string, BackStopWinRange, BackStopWinRange);                     // 逆势止赢点数
   ObjectAttr(double, MoneyStopLostValue, MoneyStopLostValue);                 // 金额止损
   ObjectAttr(double, MoneyProtectProfitValue, MoneyProtectProfitValue);       // 最大盈利保护
   ObjectAttr(int, MagicNumValue, MagicNumValue);                              // 魔法值
   ObjectAttr(bool, ShowOrdersAvgLine, ShowOrdersAvgLine);                     // 显示订单组平均线
   ObjectAttr(bool, ShowListKLine, ShowListKLine);                             // 显示连续K线指标线
   ObjectAttr(int, TargetPeriod, TargetPeriod);                                // 周期

public:
   bool              check()
     {
      if (checkBaseParameter() == false) {
        return false;  
      }
      
      if (m_EnableOpenTimes) {
         if (checkOpenTimesParameter() == false) {
           return false;
         }
      }
      
      return true;
     }
     
     bool              checkBaseParameter() { 
       int param_size = 0;
       double BackLotValue[];
       if (ParseDoubles(m_BackLotValue,BackLotValue,',') == false) 
       {
         MessageBox("逆势下单手数配置错误.");
         return false;
       }
       
       param_size = ArraySize(BackLotValue);
       
       int ForwardAddBuyRange[];
       if (ParseIntegers(m_ForwardAddBuyRange,ForwardAddBuyRange,',') == false) 
       {
         MessageBox("顺势加仓间距配置错误.");
         return false;
       }
       
       if (param_size != ArraySize(ForwardAddBuyRange)) 
       {
         MessageBox("顺势加仓间距配置参数个数错误.");
         return false;
       }
       
       int BackAddBuyRange[];
       if (ParseIntegers(m_BackAddBuyRange,BackAddBuyRange,',') == false) 
       {
         MessageBox("逆势加仓间距配置错误.");
         return false;
       }
       
       if (param_size != ArraySize(BackAddBuyRange)) 
       {
         MessageBox("逆势加仓间距配置参数个数错误.");
         return false;
       }
       
       int BackAddBuyRevertRange[];
       if (ParseIntegers(m_BackAddBuyRevertRange,BackAddBuyRevertRange,',') == false) 
       {
         MessageBox("逆势加仓回调点数配置错误.");
         return false;
       }
       
       if (param_size != ArraySize(BackAddBuyRevertRange)) 
       {
         MessageBox("逆势加仓间距配置参数个数错误.");
         return false;
       }
       
       int ForwardCloseOrderRevertRange[];
       if (ParseIntegers(m_ForwardCloseOrderRevertRange,ForwardCloseOrderRevertRange,',') == false) 
       {
         MessageBox("顺势平仓回调点数配置错误.");
         return false;
       }
       
       if (param_size != ArraySize(ForwardCloseOrderRevertRange)) 
       {
         MessageBox("顺势平仓回调点数配置参数个数错误.");
         return false;
       }
       
       int BackStopWinRange[];
       if (ParseIntegers(m_BackStopWinRange,BackStopWinRange,',') == false) 
       {
         MessageBox("逆势止赢点数配置错误.");
         return false;
       }
       
       if (param_size != ArraySize(BackStopWinRange)) 
       {
         MessageBox("逆势止赢点数配置参数个数错误.");
         return false;
       }
      
       return true;
     }
     
     bool              checkOpenTimesParameter()
     {    
        bool res = true;
        string ranges[];
        StringSplit(m_OpenTimesRanges,',',ranges);
        int size=ArraySize(ranges);
        if(size<=0)
        {
          res = false;
        }
     
        for(int i=0; i<size; i++)
        {
          string t[];
          StringSplit(ranges[i],'-',t);
          if (ArraySize(t) != 2) {
            res = false;
            break;
          }
         
          int starttime[];
          int endtime[];
         
          if (ParseIntegers(t[0],starttime,':') == false || ArraySize(starttime) != 2
              || ParseIntegers(t[1],endtime,':') == false || ArraySize(endtime) != 2) 
          {
            res = false;
            break;
          } 
         
          if (starttime[0] >= 0 && starttime[0] < 24 && starttime[1] >= 0 && starttime[1] <= 59 
             && endtime[0] >= 0 && endtime[0] < 24 && endtime[1] >= 0 && endtime[1] <= 59
             && (starttime[0] < endtime[0] || (starttime[0] == endtime[0] && starttime[1] < endtime[1] )))
          {
          }
          else {
             res = false;
             break;
          } 
        }
        
       if (res == false) MessageBox("允许开仓时间配置错误.");
       return res;
     }
  };
  
  
class GuoJiaEAOrderMatcher: public OrderMatcher {
 private:
   string m_symbol;
   int    m_magicnum;
    
 public:
    GuoJiaEAOrderMatcher(string symbol, int magicnum)
     :m_symbol(symbol),m_magicnum(magicnum) {
    }
 
    bool matches() const {
      return true;
      if (OrderMagicNumber() == m_magicnum && OrderSymbol() == m_symbol) {
        return true;
      }
      else {
        Order oo;
        PrintFormat("check order %s %d , now (%s %d)", m_symbol, m_magicnum, OrderSymbol(),OrderMagicNumber());
      }
      return false;
    }                            
  };
  
//+------------------------------------------------------------------+
//| Main EA                                                          |
//+------------------------------------------------------------------+
class GuoJiaEA: public ExpertAdvisor
  {
private:
   GuoJiaEAParam     *m_param;
   
   FxSymbol          m_fxsymbol;
   TimeSeriesData    m_data;
   MqlRates          m_updateRates[];
   //MqlRates          m_lastestRates[];
   
   OrderManager      m_ordermanager;
   GuoJiaEAOrderMatcher m_ordermatcher;
   TradingPool       m_orderpool;
   OrderTracker      m_ordertracker;
  
   OrderGroup        m_buyOrders;
   OrderGroup        m_sellOrders;
   OrderGroup        m_totalOrders;
   datetime          m_orders_outtime[2];
   
   UIRoot            m_root;
   LabeledLine       *m_LineHigh;
   LabeledLine       *m_LineLow;
   
   LabeledLine       *m_LineByeOrdersAvgPrice;
   LabeledLine       *m_LineSellOrdersAvgPrice;
   
   ReadOnlyLabel     *m_timeLable;
   ReadOnlyLabel     *m_totalLable;
   ReadOnlyLabel     *m_byeLable;
   ReadOnlyLabel     *m_sellLable;
   
   int               m_marange[];
  
protected:

public:
                     GuoJiaEA(GuoJiaEAParam *param);
                    ~GuoJiaEA()
     {
      SafeDelete(m_timeLable);
      SafeDelete(m_LineHigh);
      SafeDelete(m_LineLow);
      SafeDelete(m_LineByeOrdersAvgPrice);
      SafeDelete(m_LineSellOrdersAvgPrice);
      SafeDelete(m_totalLable);
      SafeDelete(m_byeLable);
      SafeDelete(m_sellLable);
     }

   void              initgrouporders();
   void              update();
   void              main();
   void              onTimer();
   
  private: 
   bool              InOpenTimesRange();
  
   //bool             OpenSignalFilter(int ordertype);
   int              CheckForOpen(OrderGroup *orders,int try_ordertype);
   int              CheckForClose(OrderGroup *orders, bool check_profit, bool check_close);
   int              CheckForAddLot(OrderGroup *orders);
   
   double getHigh() {
     double KBarCloseHigh = m_data.getClose(1);  
     for (int i = 1; i <= m_param.getListKLineValue(); i++) 
     {
         if (m_data.getOpen(i) > KBarCloseHigh)
           KBarCloseHigh = m_data.getOpen(i);
         if (m_data.getClose(i) > KBarCloseHigh)
           KBarCloseHigh = m_data.getClose(i);
      }
      return KBarCloseHigh;
   }
   
   double getLow() {
     double KBarCloseLow = m_data.getClose(1);   
     for (int i = 0; i < m_param.getListKLineValue(); i++) 
     {
         if (m_data.getOpen(i) < KBarCloseLow)
           KBarCloseLow = m_data.getOpen(i);
         if (m_data.getClose(i) < KBarCloseLow)
           KBarCloseLow = m_data.getClose(i);
     }
     return KBarCloseLow;
   }
   
   void getMaCrossInfo(int &out_crossindex, int &out_firstsign, int &out_trend) {
      int ma_group[300];
      ZeroMemory(ma_group);
      int cross_index = -1;
      int high_range = 0;
      int high_range_index = 0;
      int count = 300;
      
      for (int i = 0; i < count; i++) {
         double ShortMA = iMA(m_fxsymbol.getName(),m_param.getTargetPeriod(),m_param.getMAValueShort(),0,MODE_SMA,PRICE_CLOSE,i + 1);
         double LongMA = iMA(m_fxsymbol.getName(),m_param.getTargetPeriod(),m_param.getMAValueLong(),0,MODE_SMA,PRICE_CLOSE,i + 1);
         ma_group[i] = (int)((ShortMA - LongMA)/ m_fxsymbol.getPoint());
         
         if (Math::abs(ma_group[i]) > high_range) {
            high_range = Math::abs(ma_group[i]);
            high_range_index = i;
         }
         
         if (i > 0) {
            if (cross_index == -1 && Math::sign(ma_group[i]) != Math::sign(ma_group[i - 1])) {
               cross_index = i;
               count = cross_index + 2;
            }
         }
      }
      
      out_crossindex = cross_index;
      out_firstsign = Math::sign(ma_group[0]);
      out_trend = high_range_index == 0 ? 1 : -1; 
      PrintFormat("计算当前MA 趋势 %d %d 趋势 %d", out_crossindex, out_firstsign,out_trend);
   }
   
   double getRSI() {
      return iRSI(m_fxsymbol.getName(),m_param.getTargetPeriod(),m_param.getRSITimeFrame(),PRICE_CLOSE,1);
   }
   
   double getShortMA() {
     return iMA(m_fxsymbol.getName(),m_param.getTargetPeriod(),m_param.getMAValueShort(),0,MODE_SMA,PRICE_CLOSE,0);
   }
   
   double getLongMA() {
     return iMA(m_fxsymbol.getName(),m_param.getTargetPeriod(),m_param.getMAValueLong(),0,MODE_SMA,PRICE_CLOSE,0);
   } 
   
    Order* GetFirstOrder( OrderGroup *orders) {
      Order *order = NULL;
      if (orders.size() > 0)
      {
         Order::Select(orders.get(0));
         order = new Order();
         return order;
      }
      return order;
   }
   
    Order* GetLastOrder(OrderGroup *orders) {
      Order *order = NULL;
      if (orders.size() > 0)
      {
         Order::Select(orders.get(orders.size() - 1));
         order = new Order();
         return order;
      }
      return order;
    }
    
   datetime          getNearestBarDate(datetime time) const {int ps=PeriodSeconds(m_data.getPeriod());return time/ps*ps;}
   
   double GetBackLotValue(int index);
   int GetForwardAddBuyRange(int index);
   int GetBackAddBuyRange(int index);
   int GetBackAddBuyRevertRange(int index);
   int GetForwardCloseOrderRevertRange(int index);
   int GetBackStopWinRange(int index);
  
  };
//+------------------------------------------------------------------+
//| Run the main method once to force update on initialization       |
//+------------------------------------------------------------------+
GuoJiaEA::GuoJiaEA(GuoJiaEAParam *param)
   :
   m_param(param),
   m_fxsymbol(),
   m_data(m_fxsymbol.getName(), m_param.getTargetPeriod()),
   
   m_ordermanager(m_fxsymbol.getName()),
   m_ordermatcher(m_fxsymbol.getName(), param.getMagicNumValue()),
   m_orderpool(&m_ordermatcher),
   m_ordertracker(&m_orderpool),
   m_buyOrders(&m_fxsymbol),
   m_sellOrders(&m_fxsymbol),
   m_totalOrders(&m_fxsymbol),
   m_root()
  {
   m_ordermanager.setMagic(param.getMagicNumValue());
   m_ordermanager.setSlippage(5);
   m_ordermanager.setRetry(1);
  
   m_LineHigh = new LabeledLine("PriceHighLine","PriceHighLabel","",STYLE_DASHDOTDOT,clrLightPink,0);
   m_LineLow = new LabeledLine("PriceLowLine","PriceLowLabel","",STYLE_DASHDOTDOT,clrLightPink,0);
   
   m_LineByeOrdersAvgPrice = new LabeledLine("ByeOrdersAvgPrice","ByeOrdersAvgPriceLabel","",STYLE_DASHDOTDOT,clrBlue,0);
   m_LineSellOrdersAvgPrice = new LabeledLine("SellOrdersAvgPrice","SellOrdersAvgPriceLabel","",STYLE_DASHDOTDOT,clrDeepPink,0);
   
   m_timeLable = new ReadOnlyLabel("timelable", 5, 20, clrHotPink);
   m_totalLable = new ReadOnlyLabel("orderstotallable", 5, 40, clrHotPink);
   m_byeLable = new ReadOnlyLabel("ordersbyelable", 5, 60, clrHotPink);
   m_sellLable = new ReadOnlyLabel("orderselllable", 5, 80, clrHotPink);
   
   ArrayResize(m_updateRates,param.getListKLineValue());
   setupTimer(1);
   initgrouporders();
   update();
  }
  
  
 double GuoJiaEA::GetBackLotValue(int index) {  
   int i = index;
   double BackLotValue[];
   ParseDoubles(m_param.getBackLotValue(),BackLotValue,',');
   if (i >= ArraySize(BackLotValue))
      i = ArraySize(BackLotValue) - 1;
   return BackLotValue[i];
 }
 
 int GuoJiaEA::GetForwardAddBuyRange(int index) {  
   int i = index;
   int ForwardAddBuyRange[];
   ParseIntegers(m_param.getForwardAddBuyRange(),ForwardAddBuyRange,',');
   if (i >= ArraySize(ForwardAddBuyRange))
      i = ArraySize(ForwardAddBuyRange) - 1;
   return ForwardAddBuyRange[i];
 }
 
 int GuoJiaEA::GetBackAddBuyRange(int index) {  
   int i = index;
   int BackAddBuyRange[];
   ParseIntegers(m_param.getBackAddBuyRange(),BackAddBuyRange,',');
   if (i >= ArraySize(BackAddBuyRange))
      i = ArraySize(BackAddBuyRange) - 1;
   return BackAddBuyRange[i];
 }
 
int GuoJiaEA::GetBackAddBuyRevertRange(int index) {  
   int i = index;
   int BackAddBuyRevertRange[];
   ParseIntegers(m_param.getBackAddBuyRevertRange(),BackAddBuyRevertRange,',');
   if (i >= ArraySize(BackAddBuyRevertRange))
      i = ArraySize(BackAddBuyRevertRange) - 1;
   return BackAddBuyRevertRange[i];
 }
 
 int GuoJiaEA::GetForwardCloseOrderRevertRange(int index) {  
   int i = index;
   int ForwardCloseOrderRevertRange[];
   ParseIntegers(m_param.getForwardCloseOrderRevertRange(),ForwardCloseOrderRevertRange,',');
   if (i >= ArraySize(ForwardCloseOrderRevertRange))
      i = ArraySize(ForwardCloseOrderRevertRange) - 1;
   return ForwardCloseOrderRevertRange[i];
 }
 
 int GuoJiaEA::GetBackStopWinRange(int index) {  
   int i = index;
   int BackStopWinRange[];
   ParseIntegers(m_param.getBackStopWinRange(),BackStopWinRange,',');
   if (i >= ArraySize(BackStopWinRange))
      i = ArraySize(BackStopWinRange) - 1;
   return BackStopWinRange[i];
 }
  
 bool GuoJiaEA::InOpenTimesRange() {
  if (m_param.getEnableOpenTimes()) {
     datetime nowtime = m_param.getIsServerTime() ? TimeCurrent() : TimeLocal();
     MqlDateTime time_st;
     TimeToStruct(nowtime, time_st);
     
     bool res = false;
     string ranges[];
     StringSplit(m_param.getOpenTimesRanges(),',',ranges);
     int size=ArraySize(ranges); 
     for(int i=0; !res && i<size; i++)
     {
       string t[];
       StringSplit(ranges[i],'-',t);

       int starttime[];
       ParseIntegers(t[0],starttime,':');
       time_st.hour = starttime[0];
       time_st.min = starttime[1];
       time_st.sec = 0;
       datetime range_starttime = StructToTime(time_st);
       
       int endtime[];
       ParseIntegers(t[1],endtime,':');
       time_st.hour = endtime[0];
       time_st.min = endtime[1];
       time_st.sec = 0;
       datetime range_endtime = StructToTime(time_st);
       
       if (nowtime >= range_starttime && nowtime <= range_endtime) {
         res = true;
       }
     }
    
    return res;
   }
  return true;
 }
  
void              GuoJiaEA::initgrouporders() {
   foreachorder(m_orderpool) {
      Order o;
      m_totalOrders.add(o.getTicket());
      if (o.getType() == OP_BUY) {
        m_buyOrders.add(o.getTicket());
      }
      else if (o.getType() == OP_SELL) {
        m_sellOrders.add(o.getTicket());
      }
   }
   
   m_orders_outtime[0] = m_orders_outtime[1] = m_data.getTime(1);
}
  
 void GuoJiaEA::update() {
   m_data.updateCurrent();
   if (m_data.isNewBar()) {
      int bars=(int)m_data.getNewBars();
      ArrayResize(m_updateRates,bars,5);
      m_data.copyRates(1,bars,m_updateRates);
   }
   MqlDateTime server_time;
   TimeCurrent(server_time);
   MqlDateTime local_time;
   TimeLocal(local_time);
      
   m_timeLable.render(StringFormat("服务器时间: %4d/%2d/%2d %02d:%02d:%02d 本地时间: %4d/%2d/%2d %02d:%02d:%02d ", 
   server_time.year, server_time.mon, server_time.day, server_time.hour, server_time.min, server_time.sec,
   local_time.year, local_time.mon, local_time.day, local_time.hour, local_time.min, local_time.sec
   ));
   m_totalLable.render(StringFormat("订单总数: %d, 总体收益: %.2f 总手数 %.2f 平均开单价 %.2f", 
   m_totalOrders.size(), m_totalOrders.groupProfit(), m_totalOrders.groupLots(), m_totalOrders.groupAvg()));
   m_byeLable.render(StringFormat("多单总数: %d, 总体收益: %.2f 总手数 %.2f 平均开单价 %.2f", 
   m_buyOrders.size(), m_buyOrders.groupProfit(), m_buyOrders.groupLots(), m_buyOrders.groupAvg()));
   m_sellLable.render(StringFormat("空单总数: %d, 总体收益: %.2f 总手数 %.2f 平均开单价 %.2f", 
   m_sellOrders.size(), m_sellOrders.groupProfit(), m_sellOrders.groupLots(), m_sellOrders.groupAvg()));
   
   if (m_param.getEnableListKLine() && m_param.getShowListKLine()) {
      MqlDateTime lastbartime;
      TimeToStruct(m_data.getTime(0),lastbartime);
      m_LineHigh.setlablename(StringFormat("HighLine %02d:%02d:%02d-%02d:%02d:%02d diff %d",lastbartime.hour, lastbartime.min, lastbartime.sec, Hour(),Minute(),Seconds(),
        int((getHigh() - getLow())/ Point)));
      m_LineHigh.draw(getHigh(),TimeCurrent());
      
      m_LineLow.setlablename(StringFormat("LowLine KBar %d RSI%d %.2f MA%d %.2f MA%d %.2f", m_param.getListKLineValue(),
       m_param.getRSITimeFrame(),getRSI(),
       m_param.getMAValueShort(),getShortMA(),
       m_param.getMAValueLong(),getLongMA()
       ));
       
      m_LineLow.draw(getLow(),TimeCurrent());
   }
   
   //开单组平均价格
   if (m_param.getShowOrdersAvgLine()) {
      m_LineByeOrdersAvgPrice.setlablename(StringFormat("Bye Orders %2.2f %d", m_buyOrders.groupLots(),
      (int)((m_data.getClose(0) - m_buyOrders.groupAvg()) / m_fxsymbol.getPoint()) * OrderBase::D(OP_BUY)
      ));
    
      m_LineSellOrdersAvgPrice.setlablename(StringFormat("Sell Orders %2.2f %d", m_sellOrders.groupLots(),
       (int)((m_data.getClose(0) - m_sellOrders.groupAvg()) / m_fxsymbol.getPoint()) * OrderBase::D(OP_SELL)
      ));
      
      m_LineByeOrdersAvgPrice.draw(m_buyOrders.groupAvg(),TimeCurrent());
      m_LineSellOrdersAvgPrice.draw(m_sellOrders.groupAvg(),TimeCurrent());
   }
  
   m_ordertracker.track();
   
   m_root.redraw();
 }

void GuoJiaEA::main()
  {
   m_data.updateCurrent();
   if (m_data.isNewBar()) {
      int bars=(int)m_data.getNewBars();
      ArrayResize(m_updateRates,bars,5);
      m_data.copyRates(1,bars,m_updateRates);
      
       // 开单逻辑
      if (m_param.getEnableMultipleTicket() == false && m_totalOrders.size() == 0) {
         int ticket = 0;
         if ((ticket = CheckForOpen(&m_buyOrders,OP_BUY)) >  0) {
           m_totalOrders.add(ticket);
         }
         else if ((ticket = CheckForOpen(&m_sellOrders,OP_SELL)) >  0) {
           m_totalOrders.add(ticket);
         }
      }
      else if (m_param.getEnableMultipleTicket() == true){
         int ticket = 0;
         if ((ticket = CheckForOpen(&m_buyOrders,OP_BUY)) >  0) {
            m_totalOrders.add(ticket);
         }
         
         if ((ticket = CheckForOpen(&m_sellOrders,OP_SELL)) >  0) {
            m_totalOrders.add(ticket);
         }
      }
   }
  
   // 平仓 
   if (CheckForClose(&m_totalOrders, true, false) == 1) {
       m_orders_outtime[0] = m_orders_outtime[1] = TimeCurrent();
   }
   if (CheckForClose(&m_buyOrders, false, true) == 1) {
       m_orders_outtime[0] = TimeCurrent();
   }
   if (CheckForClose(&m_sellOrders, false, true) == 1) {
       m_orders_outtime[1] = TimeCurrent();
   }
   
   // 追加单逻辑  
   int ticket = 0;
   if ((ticket = CheckForAddLot(&m_buyOrders)) > 0) {
      m_totalOrders.add(ticket);
   }
   
   if ((ticket = CheckForAddLot(&m_sellOrders)) > 0) {
     m_totalOrders.add(ticket);
   }
   // 开单平仓逻辑结束
  
   update();
 }
 
 void GuoJiaEA::onTimer() {
   update();
 }
 
 /*
 bool GuoJiaEA::OpenSignalFilter(int ordertype) {
   int index = (ordertype == OP_BUY ? 0 : 1);
   int bar = m_data.getBars(m_data.getNearestBarTime(m_orders_outtime[index]), TimeCurrent());
   if (bar < m_param.getBaseMinKLineNumSinceClosed()) {
      return false;
   }
   
   return true;
 }
 */
 
 int GuoJiaEA::CheckForOpen(OrderGroup *orders, int try_ordertype)
 {
    //K线收线 开始检查开单条件
    if (m_data.getVolume(0) > 1) {
      PrintFormat("检查开单，当前Volume %d != 1 %d", m_data.getVolume(0), Volume[0]);
      return 0;
    }
   
    if (InOpenTimesRange() == false) {
       PrintFormat("检查开单，不在允许开仓时间内 %d %d", m_data.getVolume(0), Volume[0]);
       return 0;
    }
    
    if (orders.size() > 0){
      return 0;
    }
    
    //PrintFormat("在允许开仓时间内，当前Volume %d", Volume[0]);
    int ticket = 0;
    
    double short_ma = getShortMA();
    double long_ma = getLongMA();
    double rsi = getRSI();
    
    bool OpenFlag = true;
    int ordertype = -1;
    
    double open_price = m_data.getOpen(1);
    double close_price = m_data.getClose(1);
    
    int price_range = (int)((close_price - open_price) / m_fxsymbol.getPoint());
    
    if (OpenFlag && m_param.getEnableBaseMinKLineNumSinceClosed()) {
      int index = (ordertype == OP_BUY ? 0 : 1);
      int bar = m_data.getBars(getNearestBarDate(m_orders_outtime[index]), TimeCurrent());
      if (bar <= m_param.getBaseMinKLineNumSinceClosed()) {
         PrintFormat("初始开 %s 单需要最少 %d 根K线(以最后平仓时间),当前K线数 %d", OrderTypeString[ordertype], m_param.getBaseMinKLineNumSinceClosed(),bar);
         OpenFlag = false;
      }
    }
    
    
#ifdef USE_KLINE
    
    if (OpenFlag && m_param.getEnableListKLine() ) {
      do {
         if (m_param.getListKLineValue() > m_data.getBars()) {
            PrintFormat("连续波幅检查最少需要K线数 %d，当前K线数 %d ", m_param.getListKLineValue(), m_data.getBars());
            OpenFlag = false;
            break;
         }
      
         double KBarCloseHigh = getHigh();
         double KBarCloseLow = getLow();
         
         int listkline_price_range = (int)((KBarCloseHigh - KBarCloseLow) / m_fxsymbol.getPoint());
         if (Math::abs(listkline_price_range) >= m_param.getListKLineRange()) 
         {
            MqlRates klines[];
            ArrayResize(klines, m_param.getListKLineValue(), 0);
            m_data.copyRates(1,m_param.getListKLineValue(),klines);
            PriceBreakSignal price_break_signal;
             
            int bars=0;
            int size=ArraySize(klines);
            
            int newBars=0;
            for(int i=0; i< size - 1; i++)
            {
               newBars=price_break_signal.loadRate(klines[i]);
               bars+=newBars;
            }
            
            double pricebreak_low = price_break_signal.calcReversalLow();
            double pricebreak_high = price_break_signal.calcReversalHigh();
            
            price_break_signal.loadRate(klines[size -1]);
           
            if (price_break_signal.getNewBarDir() > 0) {
               ordertype = OP_BUY; //多单
               PrintFormat("统计前面K线 突破破价范围[%d %d]  多单", pricebreak_low, pricebreak_high);
            }
            else if (price_break_signal.getNewBarDir() < 0){
                ordertype = OP_SELL; //空单
                PrintFormat("统计前面K线 突破破价范围[%d %d]  空单",  pricebreak_low, pricebreak_high);
            }
            else if (price_break_signal.getNewBarDir() == 0){
                OpenFlag = false;
                PrintFormat("统计前面K线 价格 未突破破价范围[%d %d] 不开单",  pricebreak_low, pricebreak_high );
            }

            /*
            OpenFlag = true;
            
            if (Math::sign(price_range) > 0) {
              
            }
            else {
               ordertype = OP_SELL; //多单
               PrintFormat("统计前面K线 价格差 %d 大于%d  空单", Math::abs(listkline_price_range), m_param.getListKLineRange());
            }
            */
         }
         else {
            OpenFlag = false;
            PrintFormat("统计前面K线 价格差 %d 小于%d  不开单", Math::abs(listkline_price_range), m_param.getListKLineRange());
         }
      } while(0);
    }
 #endif    
    
    if (OpenFlag && m_param.getEnableAlgorithm()) {
      do {
         if (Math::abs(price_range) < m_param.getMinAlgorithmValue() || Math::abs(price_range) > m_param.getMaxAlgorithmValue()) {
            OpenFlag = false;
            PrintFormat("统计当前K线 %s 波幅%d 不在 [%d %d] 范围，不开单", Math::sign(price_range) == 1 ? "阳线": "阴线", Math::abs(price_range), m_param.getMinAlgorithmValue(),m_param.getMaxAlgorithmValue());
            break;
         }
         
         if (Math::sign(price_range) < 0 && ordertype == -1) {
            OpenFlag = true;
            ordertype = OP_SELL; //空单
            PrintFormat("统计当前K线 阴线波幅%d 空单", Math::abs(price_range));
         }
         else if (Math::sign(price_range) > 0 && ordertype == -1){
            OpenFlag = true;
            ordertype = OP_BUY; //多单
            PrintFormat("统计当前K线 阳线波幅%d 多单", Math::abs(price_range));
         }
      } while (0);
    }
    
    if (OpenFlag && m_param.getEnableMA()) {
      do {
         //当K线在MA60以上不允许开空单
         if (open_price > long_ma && close_price > long_ma) {
            if (ordertype == OP_SELL) {
               OpenFlag = false;
               PrintFormat("当K线在MA60以上不允许开空单");
               break;
            }
         }
         
         //当K线在MA60以下不允许开多单
         if (open_price < long_ma && close_price < long_ma) {
            if (ordertype == OP_BUY) {
               OpenFlag = false;
               PrintFormat("当K线在MA60以下不允许开多单");
               break;
            }
         }
         
         if (short_ma  >= long_ma) {
             if (ordertype == OP_SELL) {
               OpenFlag = false;
               PrintFormat("当MA30 上穿MA60，不允许开空单");
               break;
             }
         }
         else if (short_ma  < long_ma) {
            if (ordertype == OP_BUY) {
               OpenFlag = false;
               PrintFormat("当MA30下穿MA60，不允许开多单");
               break;
            }
         }
         
         if (m_param.getEnableMARangeTrend()) {
            int out_crossindex = -1;
            int out_firstsign = 0;
            int out_marangetrend = 0;
            getMaCrossInfo(out_crossindex, out_firstsign,out_marangetrend);
            if (out_marangetrend < 0) {
               OpenFlag = false;
               PrintFormat("MA30 MA60 间距趋势缩小, 不允许开单");
               break;
            }
         }
      } while(0);
    }
    
    if (OpenFlag && m_param.getEnableRSI()) {
      do {
         //当RSI指标低于30 不允许开空单
         if (rsi <= m_param.getRSIValueLow()) {
           if (ordertype == OP_SELL) {
               OpenFlag = false;
               PrintFormat("当RSI指标低于30 不允许开空单");
               break;
           }
         }
         
         //当RSI指标高于70 不允许开多单
         if (rsi >= m_param.getRSIValueHigh()) {
           if (ordertype == OP_BUY) {
               OpenFlag = false;
               PrintFormat("当RSI指标高于70 不允许开多单");
               break;
           }
         }
      } while(0);
    }
    
      
         
    if (OpenFlag && ordertype != -1 && try_ordertype == ordertype) {
      ticket = m_ordermanager.market(ordertype, m_param.getBaseLotValue(), 0, 0);
      if (ticket > 0) {
         orders.add(ticket);
         PrintFormat("开单");
      }
    }
 
    return ticket;   
 }
 
int GuoJiaEA::CheckForClose(OrderGroup *orders, bool check_profit, bool check_close) 
{  
   //判断已存在订单
   if (orders.size() == 0)
     return 0;
    
   bool stopall = false;
   
   //总体亏损达到阈值
   double totalprofit = orders.groupProfit() + orders.groupCommission() + orders.groupSwap();
   if (check_profit && !stopall && ((totalprofit > 0.0 && Math::abs(totalprofit) >= m_param.getMoneyProtectProfitValue()) || (totalprofit < 0.0 && Math::abs(totalprofit) >= m_param.getMoneyStopLostValue()))) {
      //止损 按照金额止损
      for (int i = 0; i < orders.size(); i++) {
        m_ordermanager.close(orders.get(i));
      }
      
      stopall = true;
   }
   
   if (check_close == false) {
      orders.clearClosed();
      return stopall ? 1 : 0;
   }
   
   Order * first_order = GetFirstOrder(orders);
   Order * last_order = GetLastOrder(orders);
     
   //顺势止赢
   //按照顺势行情回调整体出场,初始单盈利回调不出场，判断追加单盈利回调条件出场
   if (!stopall && first_order.getProfit() > 0.0 && totalprofit > 0.0 && orders.size() > 1) {
      do {
      int bars = m_data.getBars(getNearestBarDate(last_order.getOpenTime()),TimeCurrent());
      double lowestprice_since_lastorder = m_data.getLow(0);
      double highestprice_since_lastorder = m_data.getHigh(0);
      if (bars == 1) {
       //最后追加单 在当前k 线
      }
      else {
        lowestprice_since_lastorder = m_data.getLowestPrice(bars);
        highestprice_since_lastorder = m_data.getHighestPrice(bars);
      }
      
       if (first_order.getType() == OP_BUY) 
       {
          int index = orders.size() - 1 - 1;
          
          double price1 = m_fxsymbol.subPoints(highestprice_since_lastorder, GetForwardCloseOrderRevertRange(index));
          double price2 = m_fxsymbol.subPoints(orders.groupAvg(), (int)((orders.groupCommission() + orders.groupSwap()) / orders.groupLots())); 
          
          //判断顺势平仓回调价格
          if (m_fxsymbol.priceForClose(OP_BUY) <= Math::max(price1,price2)) {
              
             for (int i = 0; i < orders.size(); i++) {
                  m_ordermanager.close( orders.get(i));
             }
             
             stopall = true;
          }
       }
       else if (first_order.getType() == OP_SELL) 
       {
          int index = orders.size() - 1 - 1;
          //逆势加仓间隔判断价位
          double price1 = m_fxsymbol.addPoints(lowestprice_since_lastorder, GetForwardCloseOrderRevertRange(index));
          double price2 = m_fxsymbol.addPoints(orders.groupAvg(), int((orders.groupCommission() + orders.groupSwap()) / orders.groupLots()));
        
          //逆势回调价位判断
          if (m_fxsymbol.priceForClose(OP_SELL) >= Math::min(price1,price2)) {
             for (int i = 0; i < orders.size(); i++) {
                  m_ordermanager.close( orders.get(i));
             }
             stopall = true;
          }
       }
      } while (0);
   }
   
   if (!stopall && totalprofit > 0.0 && first_order.getProfit() < 0.0 && orders.size() > 1) {
     double group_avg_price = orders.groupAvg();
     double group_lots = orders.groupLots();
     
     int index = orders.size() - 1 - 1;
     if (first_order.getType() == OP_BUY)  {
       double price1 = m_fxsymbol.addPoints(group_avg_price, GetBackStopWinRange(index));
       
       if (m_fxsymbol.priceForClose(OP_BUY) >= price1) {
          for (int i = 0; i < orders.size(); i++) {
               m_ordermanager.close( orders.get(i));
          }
          
          PrintFormat("逆势目前订单数 %d %.2f %.2f %d %.2f",  orders.size(), group_avg_price, group_lots,GetBackStopWinRange(index), m_fxsymbol.priceForClose(OP_BUY));
          PrintFormat("逆势清空订单");
          stopall = true;
       }
     } else if (first_order.getType() == OP_SELL) {
       double price1 = m_fxsymbol.subPoints(group_avg_price, GetBackStopWinRange(index));
       if (m_fxsymbol.priceForClose(OP_SELL) <= price1) {
          for (int i = 0; i < orders.size(); i++) {
               m_ordermanager.close( orders.get(i));
          }
          stopall = true;
       }
     }
   }
   
   SafeDelete(first_order);
   SafeDelete(last_order);
   
   orders.clearClosed();
   return stopall ? 1 : 0;
}

int GuoJiaEA::CheckForAddLot(OrderGroup *orders) 
{
   //判断已存在初始单
   if (orders.size() == 0)
     return 0;
     
   double now_profit = orders.groupProfit() + orders.groupCommission() + orders.groupSwap();
   Order * first_order = GetFirstOrder(orders);
   Order * last_order = GetLastOrder(orders);
   
   int ticket = 0;
   
   do {
     if (first_order.getProfit() < 0 && last_order.getProfit() < 0) {
      //+------------------------------------------------------------------+
      //|当订单亏损开启加仓行为 类马丁
      //|   加仓开启条件，当行情大于500之后，回调100点开单
      //|   加仓间隔  500  1000  2000  （参数自己填写）
      //|   加仓手数 0.01  0.01  0.02  0.03  （参数自己填写）
      //|   加仓回调需求   100  200  300                                                                 |
      //+------------------------------------------------------------------+
   
       //不能在当前K线追加单
       int bars = m_data.getBars(last_order.getOpenTime(),m_data.getTime(0));
       if (bars == 0) {
          break;
       }
       
       double lowestprice_since_lastorder = m_data.getLowestPrice(bars);
       double highestprice_since_lastorder = m_data.getHighestPrice(bars);
       
       if (first_order.getType() == OP_BUY) 
       {
          int index = orders.size() - 1;
          //逆势加仓间隔判断价位
          double price1 = m_fxsymbol.subPoints(last_order.getOpenPrice(), GetBackAddBuyRange(index));
          //逆势回调价位判断
          double price2 = m_fxsymbol.addPoints(lowestprice_since_lastorder, GetBackAddBuyRevertRange(index));
          if (lowestprice_since_lastorder < price1) {
             if (m_fxsymbol.priceForOpen(OP_BUY) >= price2) {
               //逆势加单
               ticket = m_ordermanager.market(OP_BUY,GetBackLotValue(index),0,0);
               
               if (ticket > 0) {
                  orders.add(ticket);
                  //m_totalOrders.add(ticket);
                  PrintFormat("开单");
               }
             }
          }
       }
       else if (first_order.getType() == OP_SELL) 
       {
          int index = orders.size() - 1;
          //逆势加仓间隔判断价位
          double price1 = m_fxsymbol.addPoints(last_order.getOpenPrice(), GetBackAddBuyRange(index));
          //逆势回调价位判断
          double price2 = m_fxsymbol.subPoints(highestprice_since_lastorder, GetBackAddBuyRevertRange(index));
          
          if (highestprice_since_lastorder > price1) {
          /*
             PrintFormat("ADD LOT %.2f RANGE %d REVERT %d ,High%.2f LOW  %.2f PRICE1 %.2f PRICE2 %.2f %d now price %.2f", 
               GetBackLotValue(index),GetBackAddBuyRange(index),GetBackAddBuyRevertRange(index),
               highestprice_since_lastorder, lowestprice_since_lastorder, price1, price2, index, m_fxsymbol.priceForOpen(OP_SELL));
               */
          
             if (m_fxsymbol.priceForOpen(OP_SELL) <= price2) {
               //逆势加单
               ticket = m_ordermanager.market(OP_SELL,GetBackLotValue(index),0,0);
               if (ticket > 0) {
                  orders.add(ticket);
                  //m_totalOrders.add(ticket);
                  PrintFormat("开单");
               }
             }
          }
       }
   }
   
   if (first_order.getProfit() > 0 && last_order.getProfit() > 0) 
   {
      //不能在当前K线追加单
      int bars = m_data.getBars(last_order.getOpenTime(),m_data.getTime(0));
      if (bars == 0) {
          break;
      }
      
     //顺势追加单
     if (first_order.getProfit() > 0.0 && last_order.getProfit() > 0.0 ) {
        int index = orders.size() - 1;
        if (first_order.getType() == OP_BUY)
        {
          //顺势加仓间隔判断价位
          double price1 = m_fxsymbol.addPoints(last_order.getOpenPrice(), GetForwardAddBuyRange(index));
          
          if (m_fxsymbol.priceForOpen(OP_BUY) >= price1) {
             // 顺势加单使用初始下单手数
             ticket = m_ordermanager.market(OP_BUY, m_param.getBaseLotValue(),0,0);
             if (ticket > 0) {
                  orders.add(ticket);
                  //m_totalOrders.add(ticket);
                  PrintFormat("开单");
             }
          }
        }
        else if (first_order.getType() == OP_SELL) {
         //顺势加仓间隔判断价位
          double price1 = m_fxsymbol.subPoints(last_order.getOpenPrice(), GetForwardAddBuyRange(index));
          
          if (m_fxsymbol.priceForOpen(OP_SELL) <= price1) {
             // 顺势加单使用初始下单手数
             ticket = m_ordermanager.market(OP_SELL, m_param.getBaseLotValue(),0,0);
             if (ticket > 0) {
                  orders.add(ticket);
                  //m_totalOrders.add(ticket);
                  PrintFormat("开单");
             }
          }
        }
     }
    }
   } while (0);
 
   SafeDelete(first_order);
   SafeDelete(last_order);
  
   return ticket;
}
   
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
BEGIN_INPUT(GuoJiaEAParam)
INPUT_SEP(OpenCondition1, "*****算法******");               // 开仓条件1
INPUT(bool,EnableAlgorithm,true);                           // 算法交易
INPUT(int,MinAlgorithmValue,100);                           // 最小算法交易值
INPUT(int,MaxAlgorithmValue,2000);                          // 最大算法交易值
INPUT(bool,EnableListKLine,true);                           // 启动连续K线
INPUT(int,ListKLineValue, 10);                              // 连续K线根数
INPUT(int,ListKLineRange, 500);                             // 连续K线波幅
INPUT_SEP(OpenCondition2, "*****RSI******");                // 开仓条件2
INPUT(bool,EnableRSI,true);                                 // 启动RSI
INPUT(int,RSITimeFrame, 14);                                // RSI周期
INPUT(double,RSIValueHigh, 70.0);                           // RSI高值
INPUT(double,RSIValueLow, 30.0);                            // RSI低值
INPUT_SEP(OpenCondition3, "*****MA******");                 // 开仓条件3
INPUT(bool,EnableMA,true);                                  // 启动MA
INPUT(int,MAValueShort, 30);                                // 短均线
INPUT(int,MAValueLong, 60);                                 // 长均线
INPUT(bool,EnableMARangeTrend,true);                        // 启动MA间距趋势
INPUT_SEP(OpenTimes, "*****时间控制******");                // 开仓时间控制
INPUT(bool, EnableOpenTimes, true);                         // 启动开仓时间控制
INPUT(bool, IsServerTime, false);                            // false=本地时间 true=服务器时间
INPUT(string, OpenTimesRanges, "00:00-23:59,06:00-20:00,20:50-23:59");  // 允许开仓时间段
INPUT_SEP(BaseParameters, "*****基本参数******");           // 基本参数
INPUT(bool, EnableMultipleTicket, true);                    // 允许多单模式
INPUT(double,BaseLotValue, 0.01);                           // 初始下单手数
INPUT(bool, EnableBaseMinKLineNumSinceClosed, true);        // 开启初始下单最小K线数
INPUT(int, BaseMinKLineNumSinceClosed, 3);                  // 初始下单最小K线数(以最后平仓时间)
INPUT(string, BackLotValue, "0.02,0.03,0.04,0.05,0.06");    // 逆势下单手数
INPUT(string, ForwardAddBuyRange, "301,302,303,304,305");   // 顺势加仓间距
INPUT(string, BackAddBuyRange, "500,1000,1000,1000,1000");  // 逆势加仓间距
INPUT(string, BackAddBuyRevertRange, "151,152,153,154,155");       // 逆势加仓回调点数
INPUT(string, ForwardCloseOrderRevertRange, "150,200,250,250,250");// 顺势平仓回调点数
INPUT(string, BackStopWinRange, "100,120,80,90,150");              // 逆势止赢点数
INPUT(double, MoneyStopLostValue, 500.0);                          // 金额止损
INPUT(double, MoneyProtectProfitValue, 15.0);                      // 盈利保护
INPUT(int, MagicNumValue, 2897701);                                // 魔法值
INPUT(bool, ShowOrdersAvgLine, true);                              // 显示订单组平均线
INPUT(bool, ShowListKLine, true);                                  // 显示连续K线指标线
INPUT(int, TargetPeriod, 30);                                      // 周期
END_INPUT


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
DECLARE_EA(GuoJiaEA,true);
//+------------------------------------------------------------------+
