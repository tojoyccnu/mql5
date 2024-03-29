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

#include <Mql/Utils/File.mqh>

//注释下一行, 显示完整参数
#define USE_SHORT_PARAMETERS 1


//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
class GuoJiaEAParam: public AppParam
  {
public:
                     ObjectAttr(int,LicenseCode, LicenseCode);                                   // 授权码

                     ObjectAttr(bool,EnableListKLine,EnableListKLine);                           // 启动连续K线
                     ObjectAttr(int,ListKLineValue, ListKLineValue);                             // 连续K线根数连阳连阴
                     ObjectAttr(int,ListKLineRange, ListKLineRange);                             // 连续K线波幅(下限)
                     ObjectAttr(int,MinAlgorithmValue,MinAlgorithmValue);                        // 最小K线交易值(下限)
                     ObjectAttr(int,MaxAlgorithmValue,MaxAlgorithmValue);                        // 最大K线交易值(上限)
                     ObjectAttr(int, SignalSuperTime, SignalSuperTime);                          // 开仓信号后,开单持续时间
                     ObjectAttr(int, SpreadLimitNum , SpreadLimitNum);                           // 开仓点差限制值

                     ObjectAttr(bool, EnableOpenTimes, EnableOpenTimes);                         // 启动开仓时间控制
                     ObjectAttr(bool, IsServerTime, IsServerTime);                               // false=本地时间 true=服务器时间
                     ObjectAttr(string, OpenTimesRanges, OpenTimesRanges);                       // 允许开仓时间段
                     
                     
                     ObjectAttr(bool, EnableIndicatorFilter1, EnableIndicatorFilter1);           // 启动指标过滤算法控制
                     ObjectAttr(int, IndicatorFilter1TimeFrame, IndicatorFilter1TimeFrame);      // 指标算法时间窗口周期
                     ObjectAttr(int, IndicatorFilter1Period, IndicatorFilter1Period);            // 指标算法时间跨度周期
                     ObjectAttr(int, IndicatorFilter1Value1, IndicatorFilter1Value1);            // 指标算法限制值1
                     ObjectAttr(int, IndicatorFilter1Value2, IndicatorFilter1Value2);            // 指标算法限制值2
                     
                     
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
                     
                     ObjectAttr(bool, EnableBackAddLotsLimitEx, EnableBackAddLotsLimitEx);       // 允许逆势额外加仓限制
                     ObjectAttr(int, BackAddLotsLimitExNum, BackAddLotsLimitExNum);              // K_15线波动范围
                     
                     
                     ObjectAttr(double, MoneyStopLostValue, MoneyStopLostValue);                 // 金额止损
                     ObjectAttr(double, MoneyProtectProfitValue, MoneyProtectProfitValue);       // 最大盈利保护
                     ObjectAttr(double, FirstOrderMoneyProtectProfitValue, FirstOrderMoneyProtectProfitValue);            // 首单盈利保护
                     ObjectAttr(bool, AddBaseOrderWhenMoneyProtect, AddBaseOrderWhenMoneyProtect); // 盈利保护后补首单
                     ObjectAttr(int, MagicNumValue, MagicNumValue);                              // 魔法值
                     ObjectAttr(bool, ShowOrdersAvgLine, ShowOrdersAvgLine);                     // 显示订单组平均线
                     ObjectAttr(bool, ShowListKLine, ShowListKLine);                             // 显示连续K线指标线
                     ObjectAttr(int, TargetPeriod, TargetPeriod);                                // 周期
                     
 

public:
      long  m_licensefile_period;                    
                     

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
        
           
        if (Mql::isTesting() == false && Mql::isVisual() == false) {
            if (checkLicenseInfo() == false )
            {
               return false;
            }
        }
        else {
              m_licensefile_period = 0;              
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
     
       bool              checkLicenseInfo() {
       
         bool res = true;
         
         string file_name = IntegerToString(getLicenseCode()) + ".license";
         
         if (File::exist(file_name, false) ==  false) {
            MessageBox("授权码 licensecode, 授权文件不存在");
            return false;
         }
         
         BinaryFile license_file(file_name,  FILE_READ);
         
         //string license_start = "LICENSESTART";
         
         //license_file.readString(StringBufferLen(license_start));
         
         int file_licensecode = license_file.readInteger(4);
         int file_licensemagic = license_file.readInteger(4);
         int file_licenseaccount = license_file.readInteger(4);
         long file_licenseperiod = license_file.readLong();
         
         int file_authserver_len = license_file.readInteger(4);
         string file_authserver;
         
         if (file_authserver_len > 0)
         {
            file_authserver = license_file.readString(file_authserver_len);
         }
         
         int file_currencypairs_str_len = license_file.readInteger(4);
         string file_currencypairs;
         
         if (file_currencypairs_str_len > 0)
         {
            file_currencypairs = license_file.readString(file_currencypairs_str_len);
         }
         
         //string license_end = "LICENSEEND";
         //license_file.readString(StringBufferLen(license_end));
         
         if (getLicenseCode() != file_licensecode) {
            PrintFormat("check licensecode %d , now ( %d)", getLicenseCode(), file_licensecode );
            MessageBox("授权码 licensecode, 授权文件格式错误, 错误码 401");
            return false;
         }
         
         if (getMagicNumValue() != file_licensemagic) {
            PrintFormat("check licensemagic %d , now ( %d)",  getMagicNumValue(), file_licensemagic );
            MessageBox("授权码 licensecode, 授权文件格式错误, 错误码 402");
            return false;
         }
         
         if (file_licenseperiod < TimeCurrent() ) {
            MessageBox("授权码 licensecode, 授权文件格式错误, 错误码 403");
            return false;
         }
         
         if (file_currencypairs_str_len == 0 ) {
            MessageBox("授权码 licensecode, 授权文件格式错误, 错误码 404");
            return false;
         }
         
         if (file_licenseaccount > 0 ) {
            if (AccountInfoInteger(ACCOUNT_LOGIN) != file_licenseaccount) {
               MessageBox("授权码 licensecode, 授权文件格式错误, 错误码 405");
               return false;
            }
         }
         
         if (file_currencypairs_str_len > 0) {
             string currencypairs[];
             StringSplit(file_currencypairs,',',currencypairs);
             int size=ArraySize(currencypairs);
             if(size<=0)
             {
                MessageBox("授权码 licensecode, 授权文件格式错误, 错误码 406");
                return false;
             }
             
             bool check_res = false;
             string now_symbol = Symbol();      
             for(int i=0; i<size; i++) {
               string check_symbol = currencypairs[i];
               //PrintFormat("check currencypairs %s",  check_symbol);
               if (StringCompare(now_symbol, check_symbol, true) == 0) {
                  check_res = true;
                  break;
               }   
             }          
             
             if (check_res == false) {
                  MessageBox("授权码 licensecode, 授权文件格式错误, 错误码 407");
                  //MessageBox(StringFormat("当前货币对 %s 授权文件中未授权", now_symbol));
                  return false;
             }      
         }
         
         m_licensefile_period = file_licenseperiod;
         return true;
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

      if(OrderMagicNumber() == m_magicnum && OrderSymbol() == m_symbol)
        {
         return true;
        }
      else
        {
         //Order oo;
         //PrintFormat("check order %s %d , now (%s %d)", m_symbol, m_magicnum, OrderSymbol(),OrderMagicNumber());
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
   TimeSeriesData    m_data_15minute;
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

   void              LoadLastGrouporders();
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
     
     OrderGroupEx *    GetOrderGroupByBaseTicket(Vector<OrderGroupEx *> *orders_vector, int ticket)
     {
      OrderGroupEx *tmp = NULL;
      for(ConstVectorIterator<OrderGroupEx *> it(orders_vector); !it.end(); it.next())
        {
         OrderGroupEx *o = it.current();
         if(o.m_orders.size() == 0)
            continue;
         if (o.m_orders.get(0) == ticket) {
            return o;
         }   
        }

      return NULL;
     }
     
        void               InitOrdersSlots(Vector<OrderGroupEx *> *orders_vector,int try_ordertype)
     {
      if(orders_vector.size() == 0)
        {
         int i = 0;
         for(i = 0 ; i < m_param.getMultipleOrderGroupNum(); i++)
           {
            OrderGroupEx * try_one = new OrderGroupEx(&m_fxsymbol);
            try_one.m_order_type = try_ordertype;
            orders_vector.add(try_one);
           }
        }
      }
      
    int  FilterByIndicator(int try_ordertype) {
      if (m_param.getEnableIndicatorFilter1() == false)
          return 1;
    
      if (try_ordertype != OP_SELL && try_ordertype != OP_BUY)
      {
         return 0;
      }
    
      double val=iForce(NULL,m_param.getIndicatorFilter1TimeFrame(),m_param.getIndicatorFilter1Period(),MODE_SMA,PRICE_CLOSE,1);
      
      if (Math::sign(val) == 1 && Math::abs(val) > m_param.getIndicatorFilter1Value1() && try_ordertype == OP_SELL) {
         return 0;
      }
      else if (Math::sign(val) == -1 && Math::abs(val) > m_param.getIndicatorFilter1Value1() && try_ordertype == OP_BUY) {
         return 0;
      }
      else {
         return 1;
      }
          
      return 0;
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
   m_data_15minute(m_fxsymbol.getName(), 15),

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
   LoadLastGrouporders();
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
void              GuoJiaEA::LoadLastGrouporders()
  {      
      InitOrdersSlots(&m_buyOrders_vector, OP_BUY);
      InitOrdersSlots(&m_sellOrders_vector, OP_SELL);
  
      foreachorder(m_orderpool) {
         Order o;
         string comment = o.getComment();
         if (StringBufferLen(comment) == 0) {
            continue;
         }
       
         int ticket = (int)StringToInteger(comment);
         
         if (o.getType() == OP_BUY )         {
            OrderGroupEx * tmp;
            if (ticket == 0) {
                tmp = GetUnused(&m_buyOrders_vector);
                if (tmp == NULL) {
                  
                  continue;
                }
                tmp.m_orders.add(o.getTicket());
                tmp.m_orders_basetime = o.getOpenTime();
                tmp.m_signal = true;
                tmp.m_signalbartime = getNearestBarDate(o.getOpenTime());
            }
            else {
              tmp = GetOrderGroupByBaseTicket(&m_buyOrders_vector, ticket);
              
               if (tmp == NULL) {
                  continue;
                }
                tmp.m_orders.add(o.getTicket());              
            }
            
           
         }
         else if (o.getType() == OP_SELL) {
            OrderGroupEx * tmp;
            if (ticket == 0) {
                tmp = GetUnused(&m_sellOrders_vector);
                if (tmp == NULL) {
                  continue;
                }
                tmp.m_orders.add(o.getTicket());
             
                tmp.m_orders_basetime = o.getOpenTime();
                tmp.m_signal = true;
                tmp.m_signalbartime = getNearestBarDate(o.getOpenTime());
            }
            else {
              tmp = GetOrderGroupByBaseTicket(&m_sellOrders_vector, ticket);
              
               if (tmp == NULL) {
                  continue;
                }
                tmp.m_orders.add(o.getTicket());              
            }
         }
      }
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
      //PrintFormat("init update bar %d", bars);
      ArrayResize(m_updateRates,bars,5);
      m_data.copyRates(1,bars,m_updateRates);

     }

   MqlDateTime server_time;
   datetime now_server_time =  TimeCurrent(server_time);
   MqlDateTime local_time;
   datetime now_local_time = TimeLocal(local_time);
   
   if (m_param.m_licensefile_period != 0 && m_param.m_licensefile_period < now_server_time) {
      MessageBox("授权到期");
      ExpertRemove();
      return;
   }
   else if (m_param.m_licensefile_period != 0 && m_param.m_licensefile_period < now_server_time + 3600 * 24 ) {
      m_timeLable.render(StringFormat("服务时间: %s 授权时间: %s 即将过期",
            TimeToString(now_server_time, TIME_DATE|TIME_MINUTES),
            TimeToString(m_param.m_licensefile_period, TIME_DATE)
            ));
   }
   else if (m_param.m_licensefile_period != 0){
      m_timeLable.render(StringFormat("服务时间: %s 授权时间: %s",
            TimeToString(now_server_time, TIME_DATE|TIME_MINUTES),
            TimeToString(m_param.m_licensefile_period, TIME_DATE)
            ));
   }

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
      //PrintFormat("检查开单，当前Volume %d != 1 %d", m_data.getVolume(0), Volume[0]);
      return 0;
   }

   if(InOpenTimesRange() == false)
     {
      //PrintFormat("检查开单，不在允许开仓时间内 %d %d", m_data.getVolume(0), Volume[0]);
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
            //PrintFormat("连续波幅检查最少需要K线数 %d，当前K线数 %d ", m_param.getListKLineValue(), m_data.getBars());
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
               //PrintFormat("三根k线, 是连阳 %s", TimeToString(m_data.getTime(1)));
             }
             else {
               //PrintFormat("三根k线, 是连阴 %s", TimeToString(m_data.getTime(1)));
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
                 //PrintFormat("三根k线, 是连阳或连阴 %s, 满足10美金", TimeToString(m_data.getTime(1)));
           }
         else
           {
               //PrintFormat("三根k线, 是连阳或连阴 %s, 不满足10美金 [%f]", TimeToString(m_data.getTime(1)), Math::abs(Kbar_total));
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
            //PrintFormat("三根k线, 最小 K线不满足 2美金或3美金 [%f]", TimeToString(m_data.getTime(1)));
            OpenFlag = false;
            break;
           }

         //最大K线不超过20美金
         if(KBar_maxrange < m_fxsymbol.getPoint() * m_param.getMaxAlgorithmValue())
           {

           }
         else
           {
            //PrintFormat("三根k线, 最大 K线不满足 20 [%f]", TimeToString(m_data.getTime(1)));
            OpenFlag = false;
            break;
           }

         //顺势开单类型
         ordertype = (kbar_direction == 1 ? OP_BUY : OP_SELL);

         //检查是否与当前尝试开单类型 相符, 不相符则退出, 在另一个checkopen 处理
         if(ordertype != try_ordertype)
           {
             //PrintFormat("三根k线, 不满足尝试开单 [try_order_type %d , acture type %d]", TimeToString(m_data.getTime(1)), try_ordertype, ordertype);
            OpenFlag = false;
            break;
           }

         //点差大于50, 不开单
         if(OpenFlag && m_fxsymbol.getSpread() >= m_param.getSpreadLimitNum())
           {
            //PrintFormat("满足开首单条件, 点差大于50, 不开单");
            OpenFlag = false;
            break;
           }
           
           // iForce 指标
          if (FilterByIndicator(try_ordertype) == 0) {
            OpenFlag = false;
            break;
          }

        }
      while(0);
     }

   if(OpenFlag && ordertype != -1 && try_ordertype == ordertype)
     {
      string basecomment;
      basecomment = StringFormat("%d", 0);
      ticket = m_ordermanager.market(ordertype, m_param.getBaseLotValue(), 0, 0, basecomment);
      if(ticket > 0)
        {
         orders.add(ticket);
         if (ordertype == OP_BUY){
            //PrintFormat("开多单 %s, %d", TimeToString(m_data.getCurrentBarDate()), ticket );
         }
         else {
            //PrintFormat("开空单 %s, %d", TimeToString(m_data.getCurrentBarDate()), ticket );
         }

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
   if(check_profit && !stopall && orders.size() > 1 && ((totalprofit > 0.0 && Math::abs(totalprofit) >= m_param.getMoneyProtectProfitValue()) || (totalprofit < 0.0 && Math::abs(totalprofit) >= m_param.getMoneyStopLostValue())))
     {

      for(int i = 0; i < orders.size(); i++)
        {
         m_ordermanager.close(orders.get(i));
        }

      stopall = true;

      orders.clearClosed();
   }
   
   //判断首单, 固定止盈
   if (!stopall && orders.size() == 1) {
      if (totalprofit > 0.0 && Math::abs(totalprofit) >= m_param.getFirstOrderMoneyProtectProfitValue()) {
           for(int i = 0; i < orders.size(); i++)
           {
              m_ordermanager.close(orders.get(i));
           }
   
           stopall = true;
   
           orders.clearClosed();
      }
   }
   
//当订单距离超过2000点未加仓，且force参数大于1000以上的时候，止损平掉当前组别

//距离：
//前面开了0.01，开了0.02，行情波动开始变大，且force指标大于1000，然后行情一路波动达到了2000点，无法加仓，则平掉当前组别。

   if (!stopall && m_param.getEnableIndicatorFilter1() == true) {
      Order * last_order = GetLastOrder(orders);
      double range_point = Math::abs((m_data.getClose(0) - last_order.getOpenPrice())/m_fxsymbol.getPoint());
      double val=iForce(NULL,m_param.getIndicatorFilter1TimeFrame(),m_param.getIndicatorFilter1Period(),MODE_SMA,PRICE_CLOSE,1);
     
      if (totalprofit < 0.0 && last_order.getProfit() < 0.0
          && range_point >= m_param.getIndicatorFilter1Value2() 
          && Math::abs(val) > m_param.getIndicatorFilter1Value1()
          && ((Math::sign(val) == 1 && last_order.getType() == OP_SELL) || (Math::sign(val) == -1 && last_order.getType() == OP_BUY))
          ) {
           for(int i = 0; i < orders.size(); i++)
           {
              m_ordermanager.close(orders.get(i));
           }
   
           stopall = true;
   
           orders.clearClosed();
      }
   }


   //判断订单组
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
            
            int bars = m_data_15minute.getBars(getNearestBarDate(last_order.getOpenTime()),TimeCurrent());
            double lowestprice_since_lastorder = m_data_15minute.getLow(0);
            double highestprice_since_lastorder = m_data_15minute.getHigh(0);
            if(bars <= 3)
              {
               //最后追加单 在当前k 线
                break;
              }
            else
              {
               lowestprice_since_lastorder = m_data_15minute.getLowestPrice(bars);
               highestprice_since_lastorder = m_data_15minute.getHighestPrice(bars);
              }

            if(first_order.getType() == OP_BUY)
              {
               int index = 0;
               if (orders.size() == 1) {
                  index = 0;
               }
               else {
                  index = orders.size() - 1;
               }
             
               double price1 = m_fxsymbol.subPoints(highestprice_since_lastorder, GetForwardCloseOrderRevertRange(index));
               //double price2 = m_fxsymbol.subPoints(orders.groupAvg(), (int)((orders.groupCommission() + orders.groupSwap()) / orders.groupLots()));

               //判断顺势平仓回调价格
               if(highestprice_since_lastorder > orders.groupAvg() && m_fxsymbol.priceForClose(OP_BUY) <= price1)
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
                  int index = orders.size() - 1;
                  //
                  double price1 = m_fxsymbol.addPoints(lowestprice_since_lastorder, GetForwardCloseOrderRevertRange(index));
                  //double price2 = m_fxsymbol.addPoints(orders.groupAvg(), int((orders.groupCommission() + orders.groupSwap()) / orders.groupLots()));

                  //逆势回调价位判断
                  if(lowestprice_since_lastorder < orders.groupAvg() && m_fxsymbol.priceForClose(OP_SELL) >= price1)
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

               //PrintFormat("逆势目前订单数 %d %.2f %.2f %d %.2f",  orders.size(), group_avg_price, group_lots,GetBackStopWinRange(index), m_fxsymbol.priceForClose(OP_BUY));
               //PrintFormat("逆势清空订单");
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

   int superkbarnum  = m_param.getSignalSuperTime() * 3600/ PeriodSeconds(m_data.getPeriod());

   // 盈利保护后, 及时补基础首单
   if(stopall && totalprofit > 0 && m_param.getAddBaseOrderWhenMoneyProtect() == true)
     {
      if(m_fxsymbol.getSpread() >= m_param.getSpreadLimitNum())
        {
         //PrintFormat("盈利保护后, 满足开首单条件, 点差大于50, 不开单");
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
             string basecomment;
             basecomment = StringFormat("%d", 0);
            int ordertype = orders_ex.m_order_type;
            int  ticket = m_ordermanager.market(ordertype, m_param.getBaseLotValue(), 0, 0,basecomment);
            if(ticket > 0)
              {
               //PrintFormat("盈利保护后, 满足开首单条件, 开单 order[%d] [%d]", ordertype, ticket);
               orders.add(ticket);
               //PrintFormat("盈利保护后, 满足开首单条件, 开单 order[%d] [%d], size %d", ordertype, ticket, orders.size());
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
      
   //点差限制条件
   if (m_fxsymbol.getSpread() >= m_param.getSpreadLimitNum())
   {
      return 0;
   }
   
   
   // iForce 指标过滤
   if (FilterByIndicator(orders_ex.m_order_type) == 0) {
      return 0; 
   }
   
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
          
           
         double last_15minute_closeprice = m_data_15minute.getClose(1);

         //double lowestprice_since_lastorder = m_data.getLowestPrice(bars);
         //double highestprice_since_lastorder = m_data.getHighestPrice(bars);

         if(first_order.getType() == OP_BUY)
           {
            int index = orders.size() - 1;
            int back_range = GetBackAddBuyRange(index);
            double now_close_price = m_data.getClose(0);
            //逆势加仓间隔判断价位
            double price1 = m_fxsymbol.subPoints(last_order.getOpenPrice(), GetBackAddBuyRange(index));
            
            double price3 = m_fxsymbol.subPoints(last_15minute_closeprice, GetBackAddBuyRange(index));
            
            //PrintFormat("111 check price lastorder %f, last15min: %f, back_range: %d, [%f, %f], now price %f", last_order.getOpenPrice(), last_15minute_closeprice, back_range,  price1, price3, now_close_price);
        
            
            //逆势回调价位判断
            //double price2 = m_fxsymbol.addPoints(lowestprice_since_lastorder, GetBackAddBuyRevertRange(index));
            if(now_close_price < price1 && last_15minute_closeprice < price1)
              {
              
                  bool  sinal_res = false;
              
                  if (((m_data_15minute.getHigh(1) - m_data_15minute.getLow(1)) / m_fxsymbol.getPoint()) > m_param.getBackAddLotsLimitExNum()) {
                     sinal_res = true;
                  }
                  else if (Math::sign(m_data_15minute.getClose(1) - m_data_15minute.getOpen(1)) > 0) {
                     sinal_res = true;
                  }
                  
                  if (m_param.getEnableBackAddLotsLimitEx() && sinal_res == false) {
                     //不满足加仓条件
                     break;
                  }
                  
                  
                  //PrintFormat("open check price lastorder %f, last15min: %f, back_range: %d, [%f, %f], now price %f", last_order.getOpenPrice(), last_15minute_closeprice, back_range,  price1, price3, now_close_price);
        
                  //PrintFormat("check price lastorder %f, last15: %f, back_range: %d, %f, %f", last_order.getOpenPrice(), last_15minute_closeprice, back_range,  price1, price3 );
                  
                  string addcomment;
                  addcomment = StringFormat("%d", first_order.getTicket());
        
                  //逆势加单
                  ticket = m_ordermanager.market(OP_BUY,GetBackLotValue(index),0,0, addcomment);

                  if(ticket > 0)
                    {
                     orders.add(ticket);
                     //m_totalOrders.add(ticket);
                     //PrintFormat("开单");
                    }
                 
              }
           }
         else
            if(first_order.getType() == OP_SELL)
              {
               int index = orders.size() - 1;
               double now_close_price = m_data.getClose(0);
               //逆势加仓间隔判断价位
               double price1 = m_fxsymbol.addPoints(last_order.getOpenPrice(), GetBackAddBuyRange(index));
               
               double price3 = m_fxsymbol.addPoints(last_15minute_closeprice, GetBackAddBuyRange(index));
               
               if(now_close_price > price1 && last_15minute_closeprice > price1)
                 {
                     
                     bool  sinal_res = false;
                 
                     if (((m_data_15minute.getHigh(1) - m_data_15minute.getLow(1)) / m_fxsymbol.getPoint()) > m_param.getBackAddLotsLimitExNum()) {
                        sinal_res = true;
                     }
                     else if (Math::sign(m_data_15minute.getClose(1) - m_data_15minute.getOpen(1)) < 0) {
                        sinal_res = true;
                     }
                     
                     if (m_param.getEnableBackAddLotsLimitEx() && sinal_res == false) {
                        //不满足加仓条件
                        break;
                     }
                     
                     string addcomment;
                     addcomment = StringFormat("%d", first_order.getTicket());
                     
                 
                     //逆势加单
                     ticket = m_ordermanager.market(OP_SELL,GetBackLotValue(index),0,0, addcomment);
                     if(ticket > 0)
                       {
                        orders.add(ticket);
                        //m_totalOrders.add(ticket);
                        //PrintFormat("开单");
                       }
                    
                 }
              }
        }

      //顺势单,  这里注释掉了
      /*
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
        */
        
     }
   while(0);

   SafeDelete(first_order);
   SafeDelete(last_order);

   return ticket;
  }
  
  

#ifdef USE_SHORT_PARAMETERS       

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
BEGIN_INPUT(GuoJiaEAParam)
INPUT_SEP(AuthorityInfo1, "*****授权信息******");               // 授权信息
INPUT(int,LicenseCode, 10001);                                  // 授权码

//INPUT_SEP(OpenCondition1, "*****开仓算法******");           // 开仓条件1

FIXED_INPUT(bool,EnableListKLine,true);                           // 启动连续K线
FIXED_INPUT(int,ListKLineValue, 3);                               // 连续K线根数连阳连阴
FIXED_INPUT(int,ListKLineRange, 1000);                            // 连续K线波幅(下限)
FIXED_INPUT(int,MinAlgorithmValue,200);                           // 最小K线交易值(下限)
FIXED_INPUT(int,MaxAlgorithmValue,2000);                          // 最大K线交易值(上限)
FIXED_INPUT(int, SignalSuperTime, 72);                            // 开仓信号后,开单持续时间
INPUT(int, SpreadLimitNum , 50);                                  // 开仓点差限制值


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
//INPUT_SEP(IndicatorFilter1, "*****指标过滤算法******");          // 指标过滤算法
FIXED_INPUT(bool, EnableIndicatorFilter1, true);                   // 启动指标过滤算法控制
FIXED_INPUT(int, IndicatorFilter1TimeFrame, 15);                   // 指标算法时间窗口周期
FIXED_INPUT(int, IndicatorFilter1Period, 28);                      // 指标算法时间跨度周期
FIXED_INPUT(int, IndicatorFilter1Value1, 1000);                    // 指标算法限制值1
FIXED_INPUT(int, IndicatorFilter1Value2, 2000);                    // 指标算法限制值2


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
INPUT_SEP(BaseParameters, "*****基本参数******");           // 基本参数
INPUT(bool, EnableMultipleTicket, true);                    // 允许多单模式
INPUT(double,BaseLotValue, 0.01);                           // 初始下单手数
FIXED_INPUT(bool, EnableBaseMinKLineNumSinceClosed, true);        // 开启初始下单最小K线数
INPUT(int, MultipleOrderGroupNum, 1);                       // 允许并发订单组最大上限
INPUT(int, BaseMinKLineNumSinceClosed, 3);                  // 初始下单最小K线数(以最后平仓时间)
INPUT(string, BackLotValue, "0.02,0.03,0.04,0.05,0.06,0.07,0.08,0.09,0.10,0.11");    // 逆势下单手数
INPUT(string, ForwardAddBuyRange, "301,302,303,304,305,301,302,303,304,305");   // 顺势加仓间距
INPUT(string, BackAddBuyRange, "500,1000,1000,1000,1000,1000,1000,1000,1000,1000");  // 逆势加仓间距
INPUT(string, BackAddBuyRevertRange, "151,152,153,154,155,151,152,153,154,155");       // 逆势加仓回调点数,暂不用
INPUT(string, ForwardCloseOrderRevertRange, "25,25,25,25,25,25,25,25,25,25");// 顺势平仓回调点数,暂不用
INPUT(string, BackStopWinRange, "100,100,100,100,100,100,100,100,100,100");              // 逆势止赢点数

//INPUT_SEP(BackExParameters, "*****加仓额外限制参数******");          // 逆势加仓额外限制参数
FIXED_INPUT(bool, EnableBackAddLotsLimitEx, true);                    // 允许逆势额外加仓限制
FIXED_INPUT(int, BackAddLotsLimitExNum, 1000);                        // K_15线波动范围


INPUT(double, MoneyStopLostValue, 500.0);                          // 金额止损
INPUT(double, MoneyProtectProfitValue, 100.0);                     // 订单整体盈利保护
INPUT(double, FirstOrderMoneyProtectProfitValue, 30.0);            // 首单盈利保护
INPUT(bool, AddBaseOrderWhenMoneyProtect, true);                   // 盈利保护后补首单sa
INPUT(int, MagicNumValue, 1000001);                                // 魔法值
INPUT(bool, ShowOrdersAvgLine, false);                             // 显示订单组平均线
INPUT(bool, ShowListKLine, false);                                 // 显示连续K线指标线
FIXED_INPUT(int, TargetPeriod, 30);                                      // 周期
END_INPUT


#else

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
BEGIN_INPUT(GuoJiaEAParam)
INPUT_SEP(AuthorityInfo1, "*****授权信息******");               // 授权信息
INPUT(int,LicenseCode, 10001);                                  // 授权码

INPUT_SEP(OpenCondition1, "*****开仓算法******");               // 开仓条件1

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
INPUT(bool,EnableListKLine,true);                           // 启动连续K线
INPUT(int,ListKLineValue, 3);                               // 连续K线根数连阳连阴
INPUT(int,ListKLineRange, 1000);                            // 连续K线波幅(下限)
INPUT(int,MinAlgorithmValue,200);                           // 最小K线交易值(下限)
INPUT(int,MaxAlgorithmValue,2000);                          // 最大K线交易值(上限)
INPUT(int, SignalSuperTime, 72);                            // 开仓信号后,开单持续时间
INPUT(int, SpreadLimitNum , 50);                            // 开仓点差限制值


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
INPUT_SEP(IndicatorFilter1, "*****指标过滤算法******");      // 指标过滤算法
INPUT(bool, EnableIndicatorFilter1, true);                   // 启动指标过滤算法控制
INPUT(int, IndicatorFilter1TimeFrame, 15);                   // 指标算法时间窗口周期
INPUT(int, IndicatorFilter1Period, 28);                      // 指标算法时间跨度周期
INPUT(int, IndicatorFilter1Value1, 1000);                    // 指标算法限制值1
INPUT(int, IndicatorFilter1Value2, 2000);                    // 指标算法限制值2


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
INPUT_SEP(BaseParameters, "*****基本参数******");           // 基本参数
INPUT(bool, EnableMultipleTicket, true);                    // 允许多单模式
INPUT(double,BaseLotValue, 0.01);                           // 初始下单手数
INPUT(bool, EnableBaseMinKLineNumSinceClosed, true);        // 开启初始下单最小K线数
INPUT(int, MultipleOrderGroupNum, 1);                       // 允许并发订单组最大上限
INPUT(int, BaseMinKLineNumSinceClosed, 3);                  // 初始下单最小K线数(以最后平仓时间)
INPUT(string, BackLotValue, "0.02,0.03,0.04,0.05,0.06,0.07,0.08,0.09,0.10,0.11");    // 逆势下单手数
INPUT(string, ForwardAddBuyRange, "301,302,303,304,305,301,302,303,304,305");   // 顺势加仓间距
INPUT(string, BackAddBuyRange, "500,1000,1000,1000,1000,1000,1000,1000,1000,1000");  // 逆势加仓间距
INPUT(string, BackAddBuyRevertRange, "151,152,153,154,155,151,152,153,154,155");       // 逆势加仓回调点数,暂不用
INPUT(string, ForwardCloseOrderRevertRange, "25,25,25,25,25,25,25,25,25,25");// 顺势平仓回调点数,暂不用
INPUT(string, BackStopWinRange, "100,100,100,100,100,100,100,100,100,100");              // 逆势止赢点数

INPUT_SEP(BackExParameters, "*****加仓额外限制参数******");          // 逆势加仓额外限制参数
INPUT(bool, EnableBackAddLotsLimitEx, true);                    // 允许逆势额外加仓限制
INPUT(int, BackAddLotsLimitExNum, 1000);                        // K_15线波动范围


INPUT(double, MoneyStopLostValue, 500.0);                          // 金额止损
INPUT(double, MoneyProtectProfitValue, 100.0);                     // 订单整体盈利保护
INPUT(double, FirstOrderMoneyProtectProfitValue, 30.0);            // 首单盈利保护
INPUT(bool, AddBaseOrderWhenMoneyProtect, true);                   // 盈利保护后补首单sa
INPUT(int, MagicNumValue, 1000001);                                // 魔法值
INPUT(bool, ShowOrdersAvgLine, false);                             // 显示订单组平均线
INPUT(bool, ShowListKLine, false);                                 // 显示连续K线指标线
INPUT(int, TargetPeriod, 30);                                      // 周期
END_INPUT

#endif 

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
DECLARE_EA(GuoJiaEA,true);
//+------------------------------------------------------------------+
