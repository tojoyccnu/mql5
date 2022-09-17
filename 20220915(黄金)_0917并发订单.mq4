//+------------------------------------------------------------------+
//|                                                     20220915(黄金).mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright (C) 2015-2022, Huatao"
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

                     ObjectAttr(bool,EnableListKLine,EnableListKLine);                           // 启动连续K线
                     ObjectAttr(int,ListKLineValue, ListKLineValue);                             // 连续K线根数连阳连阴
                     ObjectAttr(int,ListKLineRange, ListKLineRange);                             // 连续K线波幅(下限)
                     ObjectAttr(int,MinAlgorithmValue,MinAlgorithmValue);                        // 最小K线交易值(下限)
                     ObjectAttr(int,MaxAlgorithmValue,MaxAlgorithmValue);                        // 最大K线交易值(上限)
                     ObjectAttr(int, SignalSuperTime, SignalSuperTime);                          // 开仓信号后,开单持续时间

                     ObjectAttr(bool, EnableOpenTimes, EnableOpenTimes);                         // 启动开仓时间控制
                     ObjectAttr(bool, IsServerTime, IsServerTime);                               // false=本地时间 true=服务器时间
                     ObjectAttr(string, OpenTimesRanges, OpenTimesRanges);                       // 允许开仓时间段
                     ObjectAttr(bool, EnableMultipleTicket, EnableMultipleTicket);               // 开启多单模式
                     ObjectAttr(int, MultipleOrderGroupNum, MultipleOrderGroupNum);              // 允许并发订单组最大上限
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
                     ObjectAttr(bool, AddBaseOrderWhenMoneyProtect, AddBaseOrderWhenMoneyProtect); // 盈利保护后补首单
                     ObjectAttr(int, MagicNumValue, MagicNumValue);                              // 魔法值
                     ObjectAttr(bool, ShowOrdersAvgLine, ShowOrdersAvgLine);                     // 显示订单组平均线
                     ObjectAttr(bool, ShowListKLine, ShowListKLine);                             // 显示连续K线指标线
                     ObjectAttr(int, TargetPeriod, TargetPeriod);                                // 周期

public:
   bool              check()
     {
      if(checkBaseParameter() == false)
        {
         return false;
        }

      if(m_EnableOpenTimes)
        {
         if(checkOpenTimesParameter() == false)
           {
            return false;
           }
        }

      return true;
     }

   bool              checkBaseParameter()
     {
      int param_size = 0;
      double BackLotValue[];
      if(ParseDoubles(m_BackLotValue,BackLotValue,',') == false)
        {
         MessageBox("逆势下单手数配置错误.");
         return false;
        }

      param_size = ArraySize(BackLotValue);

      int ForwardAddBuyRange[];
      if(ParseIntegers(m_ForwardAddBuyRange,ForwardAddBuyRange,',') == false)
        {
         MessageBox("顺势加仓间距配置错误.");
         return false;
        }

      if(param_size != ArraySize(ForwardAddBuyRange))
        {
         MessageBox("顺势加仓间距配置参数个数错误.");
         return false;
        }

      int BackAddBuyRange[];
      if(ParseIntegers(m_BackAddBuyRange,BackAddBuyRange,',') == false)
        {
         MessageBox("逆势加仓间距配置错误.");
         return false;
        }

      if(param_size != ArraySize(BackAddBuyRange))
        {
         MessageBox("逆势加仓间距配置参数个数错误.");
         return false;
        }

      int BackAddBuyRevertRange[];
      if(ParseIntegers(m_BackAddBuyRevertRange,BackAddBuyRevertRange,',') == false)
        {
         MessageBox("逆势加仓回调点数配置错误.");
         return false;
        }

      if(param_size != ArraySize(BackAddBuyRevertRange))
        {
         MessageBox("逆势加仓间距配置参数个数错误.");
         return false;
        }

      int ForwardCloseOrderRevertRange[];
      if(ParseIntegers(m_ForwardCloseOrderRevertRange,ForwardCloseOrderRevertRange,',') == false)
        {
         MessageBox("顺势平仓回调点数配置错误.");
         return false;
        }

      if(param_size != ArraySize(ForwardCloseOrderRevertRange))
        {
         MessageBox("顺势平仓回调点数配置参数个数错误.");
         return false;
        }

      int BackStopWinRange[];
      if(ParseIntegers(m_BackStopWinRange,BackStopWinRange,',') == false)
        {
         MessageBox("逆势止赢点数配置错误.");
         return false;
        }

      if(param_size != ArraySize(BackStopWinRange))
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
         if(ArraySize(t) != 2)
           {
            res = false;
            break;
           }

         int starttime[];
         int endtime[];

         if(ParseIntegers(t[0],starttime,':') == false || ArraySize(starttime) != 2
            || ParseIntegers(t[1],endtime,':') == false || ArraySize(endtime) != 2)
           {
            res = false;
            break;
           }

         if(starttime[0] >= 0 && starttime[0] < 24 && starttime[1] >= 0 && starttime[1] <= 59
            && endtime[0] >= 0 && endtime[0] < 24 && endtime[1] >= 0 && endtime[1] <= 59
            && (starttime[0] < endtime[0] || (starttime[0] == endtime[0] && starttime[1] < endtime[1])))
           {
           }
         else
           {
            res = false;
            break;
           }
        }

      if(res == false)
         MessageBox("允许开仓时间配置错误.");
      return res;
     }
  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class GuoJiaEAOrderMatcher: public OrderMatcher
  {
private:
   string            m_symbol;
   int               m_magicnum;

public:
                     GuoJiaEAOrderMatcher(string symbol, int magicnum)
                     :m_symbol(symbol),m_magicnum(magicnum)
     {
     }

   bool              matches() const
     {
      return true;
      if(OrderMagicNumber() == m_magicnum && OrderSymbol() == m_symbol)
        {
         return true;
        }
      else
        {
         Order oo;
         PrintFormat("check order %s %d , now (%s %d)", m_symbol, m_magicnum, OrderSymbol(),OrderMagicNumber());
        }
      return false;
     }
  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class OrderGroupEx
  {
public:
   OrderGroup        m_orders;
   int               m_order_type;
   datetime          m_orders_basetime;
   bool              m_signal;
   datetime          m_signalbartime;

public:

                     OrderGroupEx(FxSymbol *symbol)
      :              m_orders(symbol)
     {
      m_signal = false;
      m_order_type = -1;
     }

                     OrderGroupEx::OrderGroupEx(const OrderGroupEx &that)
     {
      m_order_type = that.m_order_type;
      m_orders = that.m_orders;
      m_signal = that.m_signal;
      m_orders_basetime = that.m_orders_basetime;

      m_signalbartime = that.m_signalbartime;
     }

                    ~OrderGroupEx()
     {
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

   Vector<OrderGroupEx *> m_buyOrders_vector;
   Vector<OrderGroupEx *> m_sellOrders_vector;

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
   void              update(bool init);
   void              main();
   void              onTimer();

private:
   bool              InOpenTimesRange();

   OrderGroupEx *    GetUnused(Vector<OrderGroupEx *> *orders_vector)
     {
      OrderGroupEx *tmp = NULL;
      for(ConstVectorIterator<OrderGroupEx *> it(orders_vector); !it.end(); it.next())
        {
         OrderGroupEx *o = it.current();
         if(o.m_orders.size() == 0)
            return o;
        }

      return NULL;
     }

   int               CheckForOpen(Vector<OrderGroupEx *> *orders_vector,int try_ordertype)
     {
      if(orders_vector.size() == 0)
        {
         int i = 0;
         for(i = 0 ; i < m_param.getMultipleOrderGroupNum(); i++)
           {
            OrderGroupEx * try_one = new OrderGroupEx(&m_fxsymbol);
            orders_vector.add(try_one);
           }
        }

      OrderGroupEx * try_one = GetUnused(orders_vector);
      if(try_one == NULL)
         return 0;

      int ticket = CheckForOpen(try_one, try_ordertype);
      if(ticket  > 0)
        {
         return 1;
        }
      else
        {

        }
      return 0;
     }

   int               CheckForClose(Vector<OrderGroupEx *> *orders_vector, bool check_profit, bool check_close)
     {
      for(ConstVectorIterator<OrderGroupEx *> it(orders_vector); !it.end(); it.next())
        {
         OrderGroupEx *o = it.current();
         if(o != NULL)
            CheckForClose(o, check_profit, check_close);
        }

      return 1;
     }

   int               CheckForAddLot(Vector<OrderGroupEx *> *orders_vector)
     {
     
      for(ConstVectorIterator<OrderGroupEx *> it(orders_vector); !it.end(); it.next())
        {
         OrderGroupEx *o = it.current();
         if(o != NULL)
            CheckForAddLot(o);
        }

      return 0;
     }


   int               CheckForOpen(OrderGroupEx *orders_ex,int try_ordertype);
   int               CheckForClose(OrderGroupEx *orders_ex, bool check_profit, bool check_close);
   int               CheckForAddLot(OrderGroupEx *orders_ex);

   double            getHigh()
     {
      double KBarCloseHigh = m_data.getClose(1);
      for(int i = 1; i <= m_param.getListKLineValue(); i++)
        {
         if(m_data.getOpen(i) > KBarCloseHigh)
            KBarCloseHigh = m_data.getOpen(i);
         if(m_data.getClose(i) > KBarCloseHigh)
            KBarCloseHigh = m_data.getClose(i);
        }
      return KBarCloseHigh;
     }

   double            getLow()
     {
      double KBarCloseLow = m_data.getClose(1);
      for(int i = 0; i < m_param.getListKLineValue(); i++)
        {
         if(m_data.getOpen(i) < KBarCloseLow)
            KBarCloseLow = m_data.getOpen(i);
         if(m_data.getClose(i) < KBarCloseLow)
            KBarCloseLow = m_data.getClose(i);
        }
      return KBarCloseLow;
     }


   int               GetOrderGroupType(OrderGroup *orders)
     {
      if(orders.size() > 0)
        {
         Order::Select(orders.get(0));
         return Order::Type();
        }
      return -1;
     }

   Order*            GetFirstOrder(OrderGroup *orders)
     {
      Order *order = NULL;
      if(orders.size() > 0)
        {
         Order::Select(orders.get(0));
         order = new Order();
         return order;
        }
      return order;
     }

   Order*            GetLastOrder(OrderGroup *orders)
     {
      Order *order = NULL;
      if(orders.size() > 0)
        {
         Order::Select(orders.get(orders.size() - 1));
         order = new Order();
         return order;
        }
      return order;
     }

   datetime          getNearestBarDate(datetime time) const {int ps=PeriodSeconds(m_data.getPeriod()); return time/ps*ps;}

   double            GetBackLotValue(int index);
   int               GetForwardAddBuyRange(int index);
   int               GetBackAddBuyRange(int index);
   int               GetBackAddBuyRevertRange(int index);
   int               GetForwardCloseOrderRevertRange(int index);
   int               GetBackStopWinRange(int index);

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
   update(true);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GuoJiaEA::GetBackLotValue(int index)
  {
   int i = index;
   double BackLotValue[];
   ParseDoubles(m_param.getBackLotValue(),BackLotValue,',');
   if(i >= ArraySize(BackLotValue))
      i = ArraySize(BackLotValue) - 1;
   return BackLotValue[i];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GuoJiaEA::GetForwardAddBuyRange(int index)
  {
   int i = index;
   int ForwardAddBuyRange[];
   ParseIntegers(m_param.getForwardAddBuyRange(),ForwardAddBuyRange,',');
   if(i >= ArraySize(ForwardAddBuyRange))
      i = ArraySize(ForwardAddBuyRange) - 1;
   return ForwardAddBuyRange[i];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GuoJiaEA::GetBackAddBuyRange(int index)
  {
   int i = index;
   int BackAddBuyRange[];
   ParseIntegers(m_param.getBackAddBuyRange(),BackAddBuyRange,',');
   if(i >= ArraySize(BackAddBuyRange))
      i = ArraySize(BackAddBuyRange) - 1;
   return BackAddBuyRange[i];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GuoJiaEA::GetBackAddBuyRevertRange(int index)
  {
   int i = index;
   int BackAddBuyRevertRange[];
   ParseIntegers(m_param.getBackAddBuyRevertRange(),BackAddBuyRevertRange,',');
   if(i >= ArraySize(BackAddBuyRevertRange))
      i = ArraySize(BackAddBuyRevertRange) - 1;
   return BackAddBuyRevertRange[i];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GuoJiaEA::GetForwardCloseOrderRevertRange(int index)
  {
   int i = index;
   int ForwardCloseOrderRevertRange[];
   ParseIntegers(m_param.getForwardCloseOrderRevertRange(),ForwardCloseOrderRevertRange,',');
   if(i >= ArraySize(ForwardCloseOrderRevertRange))
      i = ArraySize(ForwardCloseOrderRevertRange) - 1;
   return ForwardCloseOrderRevertRange[i];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GuoJiaEA::GetBackStopWinRange(int index)
  {
   int i = index;
   int BackStopWinRange[];
   ParseIntegers(m_param.getBackStopWinRange(),BackStopWinRange,',');
   if(i >= ArraySize(BackStopWinRange))
      i = ArraySize(BackStopWinRange) - 1;
   return BackStopWinRange[i];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool GuoJiaEA::InOpenTimesRange()
  {
   if(m_param.getEnableOpenTimes())
     {
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

         if(nowtime >= range_starttime && nowtime <= range_endtime)
           {
            res = true;
           }
        }

      return res;
     }
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void              GuoJiaEA::initgrouporders()
  {
   /*
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
      */
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GuoJiaEA::update(bool init)
  {
   m_data.updateCurrent();
   if(m_data.isNewBar())
     {
      int bars=(int)m_data.getNewBars();
      PrintFormat("init update bar %d", bars);
      ArrayResize(m_updateRates,bars,5);
      m_data.copyRates(1,bars,m_updateRates);

      /*
      PrintFormat("last bar %s", TimeToString(m_data.getTime(2)));
      PrintFormat("current bar %s", TimeToString(m_data.getCurrentBarDate()));

      PrintFormat("last bar to current bar %d", m_data.getBars(m_data.getTime(2), m_data.getCurrentBarDate()));
      */
     }

   MqlDateTime server_time;
   TimeCurrent(server_time);
   MqlDateTime local_time;
   TimeLocal(local_time);

   /*
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
   */

   if(m_param.getEnableListKLine() && m_param.getShowListKLine())
     {
      /*
      MqlDateTime lastbartime;
      TimeToStruct(m_data.getTime(0),lastbartime);
      m_LineHigh.setlablename(StringFormat("HighLine %02d:%02d:%02d-%02d:%02d:%02d diff %d",lastbartime.hour, lastbartime.min, lastbartime.sec, Hour(),Minute(),Seconds(),
        int((getHigh() - getLow())/ Point)));
      //m_LineHigh.draw(getHigh(),TimeCurrent());


      m_LineLow.setlablename(StringFormat("LowLine KBar %d RSI%d %.2f MA%d %.2f MA%d %.2f", m_param.getListKLineValue(),
       m_param.getRSITimeFrame(),getRSI(),
       m_param.getMAValueShort(),getShortMA(),
       m_param.getMAValueLong(),getLongMA()
       ));


      //m_LineLow.draw(getLow(),TimeCurrent());
      */
     }

//开单组平均价格
   if(m_param.getShowOrdersAvgLine())
     {
      /*
         m_LineByeOrdersAvgPrice.setlablename(StringFormat("Bye Orders %2.2f %d", m_buyOrders.groupLots(),
         (int)((m_data.getClose(0) - m_buyOrders.groupAvg()) / m_fxsymbol.getPoint()) * OrderBase::D(OP_BUY)
         ));

         m_LineSellOrdersAvgPrice.setlablename(StringFormat("Sell Orders %2.2f %d", m_sellOrders.groupLots(),
          (int)((m_data.getClose(0) - m_sellOrders.groupAvg()) / m_fxsymbol.getPoint()) * OrderBase::D(OP_SELL)
         ));

         m_LineByeOrdersAvgPrice.draw(m_buyOrders.groupAvg(),TimeCurrent());
         m_LineSellOrdersAvgPrice.draw(m_sellOrders.groupAvg(),TimeCurrent());
         */
     }

   m_ordertracker.track();

   m_root.redraw();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GuoJiaEA::main()
  {
   m_data.updateCurrent();
   if(m_data.isNewBar())
     {
      int bars=(int)m_data.getNewBars();
      ArrayResize(m_updateRates,bars,5);
      m_data.copyRates(1,bars,m_updateRates);

      int res = 0;
      
      if((res = CheckForOpen(&m_buyOrders_vector,OP_BUY)) >  0)
        {

        }

      res = 0;
      if((res = CheckForOpen(&m_sellOrders_vector,OP_SELL)) >  0)
        {

        }
     }


   if(CheckForClose(&m_buyOrders_vector, true, true) == 1)
     {
      //m_orders_outtime[0] = TimeCurrent();
     }
   if(CheckForClose(&m_sellOrders_vector, true, true) == 1)
     {
      //m_orders_outtime[1] = TimeCurrent();
     }

// 追加单逻辑

   int ticket = 0;
   if((ticket = CheckForAddLot(&m_buyOrders_vector)) > 0)
     {
      //m_totalOrders.add(ticket);
     }

   if((ticket = CheckForAddLot(&m_sellOrders_vector)) > 0)
     {
      //m_totalOrders.add(ticket);
     }
// 开单平仓逻辑结束

   update(false);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GuoJiaEA::onTimer()
  {
   update(false);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GuoJiaEA::CheckForOpen(OrderGroupEx *orders_ex, int try_ordertype)
  {
   //K线收线 开始检查开单条件
   if(m_data.getVolume(0) > 1)
   {
      PrintFormat("检查开单，当前Volume %d != 1 %d", m_data.getVolume(0), Volume[0]);
      return 0;
   }

   if(InOpenTimesRange() == false)
     {
      PrintFormat("检查开单，不在允许开仓时间内 %d %d", m_data.getVolume(0), Volume[0]);
      return 0;
     }

   OrderGroup *orders = &orders_ex.m_orders;

   if(orders.size() > 0)
   {
      return 0;
   }

//PrintFormat("在允许开仓时间内，当前Volume %d", Volume[0]);
   int ticket = 0;

   bool OpenFlag = true;
   int ordertype = -1;

   double open_price = m_data.getOpen(1);
   double close_price = m_data.getClose(1);

   int price_range = (int)((close_price - open_price) / m_fxsymbol.getPoint());

   /*
   if (OpenFlag && m_param.getEnableBaseMinKLineNumSinceClosed()) {
     int index = (ordertype == OP_BUY ? 0 : 1);
     int bar = m_data.getBars(getNearestBarDate(m_orders_outtime[index]), TimeCurrent());
     if (bar <= m_param.getBaseMinKLineNumSinceClosed()) {
        PrintFormat("初始开 %s 单需要最少 %d 根K线(以最后平仓时间),当前K线数 %d", OrderTypeString[ordertype], m_param.getBaseMinKLineNumSinceClosed(),bar);
        OpenFlag = false;
     }
   }
   */

   if(OpenFlag && m_param.getEnableListKLine())
     {
      do
        {
         if(m_param.getListKLineValue() > m_data.getBars())
         {
            PrintFormat("连续波幅检查最少需要K线数 %d，当前K线数 %d ", m_param.getListKLineValue(), m_data.getBars());
            OpenFlag = false;
            break;
         }

         //判断三根K线,是否同阳,同阴
         double KBar_one = m_data.getClose(1) - m_data.getOpen(1);
         double KBar_two = m_data.getClose(2) - m_data.getOpen(2);
         double KBar_three = m_data.getClose(3) - m_data.getOpen(3);

         int kbar_direction = Math::sign(KBar_one);
         // 1为阳线, -1 为阴线

         if(kbar_direction == Math::sign(KBar_two) && kbar_direction == Math::sign(KBar_three))
           {
            //是同一类型K线
            OpenFlag = true;
            if (kbar_direction == 1) {
               PrintFormat("三根k线, 是连阳 %s", TimeToString(m_data.getTime(1)));
             }
             else {
               PrintFormat("三根k线, 是连阴 %s", TimeToString(m_data.getTime(1)));
             }
           }
         else
           {
            //不是同一类型K线
            //PrintFormat("三根k线, 不是连阳或连阴");
            //PrintFormat("三根k线, 不是连阳或连阴 %s", TimeToString(m_data.getTime(1)));
            OpenFlag = false;
            break;
           }
           
                      
           double Kbar_total = m_data.getClose(1) - m_data.getOpen(3);
         //三连阳， 3根K线 波动总和 大于10美金
         if(Math::abs(Kbar_total) >= m_fxsymbol.getPoint() * m_param.getListKLineRange())
           {
                 //PrintFormat("", m_param.getListKLineValue(), m_data.getBars());
                 PrintFormat("三根k线, 是连阳或连阴 %s, 满足10美金", TimeToString(m_data.getTime(1)));
           }
         else
           {
               PrintFormat("三根k线, 是连阳或连阴 %s, 不满足10美金 [%f]", TimeToString(m_data.getTime(1)), Math::abs(Kbar_total));
               OpenFlag = false;
               break;
           }  
           

         double KBar_one_abs = Math::abs(KBar_one);
         double KBar_two_abs = Math::abs(KBar_two);
         double KBar_three_abs = Math::abs(KBar_three);

         double KBar_maxrange = 0;
         KBar_maxrange = Math::max(KBar_one_abs,KBar_two_abs);
         KBar_maxrange = Math::max(KBar_maxrange,KBar_two_abs);

         double KBar_minrange = 0;
         KBar_minrange = Math::min(KBar_one_abs,KBar_two_abs);
         KBar_minrange = Math::min(KBar_minrange,KBar_two_abs);

         //最小K线大于2美金，或者3美金
         if(KBar_minrange > m_fxsymbol.getPoint() * m_param.getMinAlgorithmValue())
           {

           }
         else
           {
            PrintFormat("三根k线, 最小 K线不满足 2美金或3美金 [%f]", TimeToString(m_data.getTime(1)));
            OpenFlag = false;
            break;
           }

         //最大K线不超过20美金
         if(KBar_maxrange < m_fxsymbol.getPoint() * m_param.getMaxAlgorithmValue())
           {

           }
         else
           {
            PrintFormat("三根k线, 最大 K线不满足 20 [%f]", TimeToString(m_data.getTime(1)));
            OpenFlag = false;
            break;
           }

         //顺势开单类型
         ordertype = (kbar_direction == 1 ? OP_BUY : OP_SELL);

         //检查是否与当前尝试开单类型 相符, 不相符则退出, 在另一个checkopen 处理
         if(ordertype != try_ordertype)
           {
             PrintFormat("三根k线, 不满足尝试开单 [try_order_type %d , acture type %d]", TimeToString(m_data.getTime(1)), try_ordertype, ordertype);
            OpenFlag = false;
            break;
           }

         //点差大于50, 不开单
         if(OpenFlag && m_fxsymbol.getSpread() >= 50)
           {
            PrintFormat("满足开首单条件, 点差大于50, 不开单");
            OpenFlag = false;
            break;
           }

        }
      while(0);
     }

   if(OpenFlag && ordertype != -1 && try_ordertype == ordertype)
     {
      ticket = m_ordermanager.market(ordertype, m_param.getBaseLotValue(), 0, 0);
      if(ticket > 0)
        {
         orders.add(ticket);
         if (ordertype == OP_BUY)
            PrintFormat("开多单 %s, %d", TimeToString(m_data.getCurrentBarDate()), ticket );
         else
            PrintFormat("开空单 %s, %d", TimeToString(m_data.getCurrentBarDate()), ticket );

         orders_ex.m_order_type = ordertype;
         orders_ex.m_signal = true;
         orders_ex.m_orders_basetime = TimeCurrent();
         orders_ex.m_signalbartime = m_data.getCurrentBarDate();
        }
     }

   return ticket;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GuoJiaEA::CheckForClose(OrderGroupEx *orders_ex, bool check_profit, bool check_close)
  {
    if (orders_ex == NULL)
      return 0;
  
   OrderGroup *orders = &orders_ex.m_orders;
//判断已存在订单
   if(orders.size() == 0)
      return 0;

   bool stopall = false;

//订单组 达到盈利保护, 或止损保护条件
   double totalprofit = orders.groupProfit() + orders.groupCommission() + orders.groupSwap();
   if(check_profit && !stopall && ((totalprofit > 0.0 && Math::abs(totalprofit) >= m_param.getMoneyProtectProfitValue()) || (totalprofit < 0.0 && Math::abs(totalprofit) >= m_param.getMoneyStopLostValue())))
     {

      for(int i = 0; i < orders.size(); i++)
        {
         m_ordermanager.close(orders.get(i));
        }

      stopall = true;

      orders.clearClosed();
     }

/*
   if(!stopall)
     {
      Order * first_order = GetFirstOrder(orders);
      Order * last_order = GetLastOrder(orders);

      //顺势止赢
      //按照顺势行情回调整体出场,初始单盈利回调不出场，判断追加单盈利回调条件出场
      if(!stopall && first_order.getProfit() > 0.0 && totalprofit > 0.0 && orders.size() > 1)
        {
         do
           {
            int bars = m_data.getBars(getNearestBarDate(last_order.getOpenTime()),TimeCurrent());
            double lowestprice_since_lastorder = m_data.getLow(0);
            double highestprice_since_lastorder = m_data.getHigh(0);
            if(bars == 1)
              {
               //最后追加单 在当前k 线
              }
            else
              {
               lowestprice_since_lastorder = m_data.getLowestPrice(bars);
               highestprice_since_lastorder = m_data.getHighestPrice(bars);
              }

            if(first_order.getType() == OP_BUY)
              {
               int index = orders.size() - 1 - 1;

               double price1 = m_fxsymbol.subPoints(highestprice_since_lastorder, GetForwardCloseOrderRevertRange(index));
               double price2 = m_fxsymbol.subPoints(orders.groupAvg(), (int)((orders.groupCommission() + orders.groupSwap()) / orders.groupLots()));

               //判断顺势平仓回调价格
               if(m_fxsymbol.priceForClose(OP_BUY) <= Math::max(price1,price2))
                 {

                  for(int i = 0; i < orders.size(); i++)
                    {
                     m_ordermanager.close(orders.get(i));
                    }

                  stopall = true;
                 }
              }
            else
               if(first_order.getType() == OP_SELL)
                 {
                  int index = orders.size() - 1 - 1;
                  //逆势加仓间隔判断价位
                  double price1 = m_fxsymbol.addPoints(lowestprice_since_lastorder, GetForwardCloseOrderRevertRange(index));
                  double price2 = m_fxsymbol.addPoints(orders.groupAvg(), int((orders.groupCommission() + orders.groupSwap()) / orders.groupLots()));

                  //逆势回调价位判断
                  if(m_fxsymbol.priceForClose(OP_SELL) >= Math::min(price1,price2))
                    {
                     for(int i = 0; i < orders.size(); i++)
                       {
                        m_ordermanager.close(orders.get(i));
                       }
                     stopall = true;
                    }
                 }
           }
         while(0);
        }

      if(!stopall && totalprofit > 0.0 && first_order.getProfit() < 0.0 && orders.size() > 1)
        {
         double group_avg_price = orders.groupAvg();
         double group_lots = orders.groupLots();

         int index = orders.size() - 1 - 1;
         if(first_order.getType() == OP_BUY)
           {
            double price1 = m_fxsymbol.addPoints(group_avg_price, GetBackStopWinRange(index));

            if(m_fxsymbol.priceForClose(OP_BUY) >= price1)
              {
               for(int i = 0; i < orders.size(); i++)
                 {
                  m_ordermanager.close(orders.get(i));
                 }

               PrintFormat("逆势目前订单数 %d %.2f %.2f %d %.2f",  orders.size(), group_avg_price, group_lots,GetBackStopWinRange(index), m_fxsymbol.priceForClose(OP_BUY));
               PrintFormat("逆势清空订单");
               stopall = true;
              }
           }
         else
            if(first_order.getType() == OP_SELL)
              {
               double price1 = m_fxsymbol.subPoints(group_avg_price, GetBackStopWinRange(index));
               if(m_fxsymbol.priceForClose(OP_SELL) <= price1)
                 {
                  for(int i = 0; i < orders.size(); i++)
                    {
                     m_ordermanager.close(orders.get(i));
                    }
                  stopall = true;
                 }
              }
        }

      SafeDelete(first_order);
      SafeDelete(last_order);
     }

   orders.clearClosed();
*/

   int superkbarnum  = m_param.getSignalSuperTime() * 3600/ PeriodSeconds(m_data.getPeriod());

// 盈利保护后, 及时补基础首单
   if(stopall && totalprofit > 0 && m_param.getAddBaseOrderWhenMoneyProtect() == true)
     {
      if(m_fxsymbol.getSpread() >= 50)
        {
         PrintFormat("盈利保护后, 满足开首单条件, 点差大于50, 不开单");
         orders_ex.m_orders_basetime = 0;
         orders_ex.m_signalbartime = 0;
         orders_ex.m_signal = false;
        }
      else
         if(m_data.getBars(orders_ex.m_signalbartime, m_data.getCurrentBarDate()) >  superkbarnum)
           {
            orders_ex.m_orders_basetime = 0;
            orders_ex.m_signalbartime = 0;
            orders_ex.m_signal = false;
           }
         else
           {
            int ordertype = orders_ex.m_order_type;
            int  ticket = m_ordermanager.market(ordertype, m_param.getBaseLotValue(), 0, 0);
            if(ticket > 0)
              {
               PrintFormat("盈利保护后, 满足开首单条件, 开单 order[%d] [%d]", ordertype, ticket);
               orders.add(ticket);
               orders_ex.m_orders_basetime = TimeCurrent();
              }
           }
     }

   return stopall ? 1 : 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GuoJiaEA::CheckForAddLot(OrderGroupEx *orders_ex)
  {
   if (orders_ex == NULL)
      return 0;
   OrderGroup *orders = &orders_ex.m_orders;

//判断已存在初始单
   if(orders.size() == 0)
      return 0;

   double now_profit = orders.groupProfit() + orders.groupCommission() + orders.groupSwap();
   Order * first_order = GetFirstOrder(orders);
   Order * last_order = GetLastOrder(orders);

   int ticket = 0;

   do
     {
      if(first_order.getProfit() < 0 && last_order.getProfit() < 0)
        {
         //+------------------------------------------------------------------+
         //|当订单亏损开启加仓行为 类马丁
         //|   加仓开启条件，当行情大于500之后，回调100点开单
         //|   加仓间隔  500  1000  2000  （参数自己填写）
         //|   加仓手数 0.01  0.01  0.02  0.03  （参数自己填写）
         //|   加仓回调需求   100  200  300                                                                 |
         //+------------------------------------------------------------------+

         //不能在当前K线追加单
         int bars = m_data.getBars(last_order.getOpenTime(),m_data.getTime(0));
         if(bars == 0)
           {
            break;
           }

         double lowestprice_since_lastorder = m_data.getLowestPrice(bars);
         double highestprice_since_lastorder = m_data.getHighestPrice(bars);

         if(first_order.getType() == OP_BUY)
           {
            int index = orders.size() - 1;
            //逆势加仓间隔判断价位
            double price1 = m_fxsymbol.subPoints(last_order.getOpenPrice(), GetBackAddBuyRange(index));
            //逆势回调价位判断
            double price2 = m_fxsymbol.addPoints(lowestprice_since_lastorder, GetBackAddBuyRevertRange(index));
            if(lowestprice_since_lastorder < price1)
              {
               if(m_fxsymbol.priceForOpen(OP_BUY) >= price2)
                 {
                  //逆势加单
                  ticket = m_ordermanager.market(OP_BUY,GetBackLotValue(index),0,0);

                  if(ticket > 0)
                    {
                     orders.add(ticket);
                     //m_totalOrders.add(ticket);
                     PrintFormat("开单");
                    }
                 }
              }
           }
         else
            if(first_order.getType() == OP_SELL)
              {
               int index = orders.size() - 1;
               //逆势加仓间隔判断价位
               double price1 = m_fxsymbol.addPoints(last_order.getOpenPrice(), GetBackAddBuyRange(index));
               //逆势回调价位判断
               double price2 = m_fxsymbol.subPoints(highestprice_since_lastorder, GetBackAddBuyRevertRange(index));

               if(highestprice_since_lastorder > price1)
                 {
                  /*
                     PrintFormat("ADD LOT %.2f RANGE %d REVERT %d ,High%.2f LOW  %.2f PRICE1 %.2f PRICE2 %.2f %d now price %.2f",
                       GetBackLotValue(index),GetBackAddBuyRange(index),GetBackAddBuyRevertRange(index),
                       highestprice_since_lastorder, lowestprice_since_lastorder, price1, price2, index, m_fxsymbol.priceForOpen(OP_SELL));
                       */

                  if(m_fxsymbol.priceForOpen(OP_SELL) <= price2)
                    {
                     //逆势加单
                     ticket = m_ordermanager.market(OP_SELL,GetBackLotValue(index),0,0);
                     if(ticket > 0)
                       {
                        orders.add(ticket);
                        //m_totalOrders.add(ticket);
                        PrintFormat("开单");
                       }
                    }
                 }
              }
        }

      if(first_order.getProfit() > 0 && last_order.getProfit() > 0)
        {
         //不能在当前K线追加单
         int bars = m_data.getBars(last_order.getOpenTime(),m_data.getTime(0));
         if(bars == 0)
           {
            break;
           }

         //顺势追加单
         if(first_order.getProfit() > 0.0 && last_order.getProfit() > 0.0)
           {
            int index = orders.size() - 1;
            if(first_order.getType() == OP_BUY)
              {
               //顺势加仓间隔判断价位
               double price1 = m_fxsymbol.addPoints(last_order.getOpenPrice(), GetForwardAddBuyRange(index));

               if(m_fxsymbol.priceForOpen(OP_BUY) >= price1)
                 {
                  // 顺势加单使用初始下单手数
                  ticket = m_ordermanager.market(OP_BUY, m_param.getBaseLotValue(),0,0);
                  if(ticket > 0)
                    {
                     orders.add(ticket);
                     //m_totalOrders.add(ticket);
                     PrintFormat("开单");
                    }
                 }
              }
            else
               if(first_order.getType() == OP_SELL)
                 {
                  //顺势加仓间隔判断价位
                  double price1 = m_fxsymbol.subPoints(last_order.getOpenPrice(), GetForwardAddBuyRange(index));

                  if(m_fxsymbol.priceForOpen(OP_SELL) <= price1)
                    {
                     // 顺势加单使用初始下单手数
                     ticket = m_ordermanager.market(OP_SELL, m_param.getBaseLotValue(),0,0);
                     if(ticket > 0)
                       {
                        orders.add(ticket);
                        //m_totalOrders.add(ticket);
                        PrintFormat("开单");
                       }
                    }
                 }
           }
        }
     }
   while(0);

   SafeDelete(first_order);
   SafeDelete(last_order);

   return ticket;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
BEGIN_INPUT(GuoJiaEAParam)
INPUT_SEP(OpenCondition1, "*****开仓算法******");               // 开仓条件1

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
INPUT(bool,EnableListKLine,true);                           // 启动连续K线
INPUT(int,ListKLineValue, 3);                               // 连续K线根数连阳连阴
INPUT(int,ListKLineRange, 500);                            // 连续K线波幅(下限)
INPUT(int,MinAlgorithmValue,100);                           // 最小K线交易值(下限)
INPUT(int,MaxAlgorithmValue,500);                          // 最大K线交易值(上限)
INPUT(int, SignalSuperTime, 72);                            // 开仓信号后,开单持续时间


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
INPUT_SEP(OpenTimes, "*****时间控制******");                // 开仓时间控制
INPUT(bool, EnableOpenTimes, true);                         // 启动开仓时间控制
INPUT(bool, IsServerTime, false);                            // false=本地时间 true=服务器时间
INPUT(string, OpenTimesRanges, "00:00-23:59,06:00-20:00,20:50-23:59");  // 允许开仓时间段

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
INPUT_SEP(BaseParameters, "*****基本参数******");           // 基本参数
INPUT(bool, EnableMultipleTicket, true);                    // 允许多单模式
INPUT(double,BaseLotValue, 0.01);                           // 初始下单手数
INPUT(bool, EnableBaseMinKLineNumSinceClosed, true);        // 开启初始下单最小K线数
INPUT(int, MultipleOrderGroupNum, 5);                       // 允许并发订单组最大上限
INPUT(int, BaseMinKLineNumSinceClosed, 3);                  // 初始下单最小K线数(以最后平仓时间)
INPUT(string, BackLotValue, "0.02,0.03,0.04,0.05,0.06");    // 逆势下单手数
INPUT(string, ForwardAddBuyRange, "301,302,303,304,305");   // 顺势加仓间距
INPUT(string, BackAddBuyRange, "500,1000,1000,1000,1000");  // 逆势加仓间距
INPUT(string, BackAddBuyRevertRange, "151,152,153,154,155");       // 逆势加仓回调点数
INPUT(string, ForwardCloseOrderRevertRange, "150,200,250,250,250");// 顺势平仓回调点数
INPUT(string, BackStopWinRange, "100,120,80,90,150");              // 逆势止赢点数
INPUT(double, MoneyStopLostValue, 500.0);                          // 金额止损
INPUT(double, MoneyProtectProfitValue, 100.0);                     // 盈利保护
INPUT(bool, AddBaseOrderWhenMoneyProtect, true);                   // 盈利保护后补首单
INPUT(int, MagicNumValue, 2022091501);                             // 魔法值
INPUT(bool, ShowOrdersAvgLine, false);                             // 显示订单组平均线
INPUT(bool, ShowListKLine, false);                                 // 显示连续K线指标线
INPUT(int, TargetPeriod, 30);                                      // 周期
END_INPUT


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
DECLARE_EA(GuoJiaEA,true);
//+------------------------------------------------------------------+
