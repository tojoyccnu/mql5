//+------------------------------------------------------------------+
//|                                                   GenLicense.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Huatao"
#property link      "tojoyccnu@163.com"
#property version   "2.00"

#property strict
#property script_show_inputs

#property description "授权人员生成授权license 放在DATAPATH/Files (Experts同一级目录)目录;\n分发客户时,应将license文件放在对应目录,才能被识别\n授权码,授权魔法值,授权日期,授权货币对,不能为空\n授权账户和授权服务器,可以为空,即表示不受限"


#include <Mql/Lang/Script.mqh>
#include <Mql/Utils/File.mqh>


//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
class GuoJiaParam: public AppParam
  {
public:
   ObjectAttr(int,LicenseCode, LicenseCode);                            // 授权码
   ObjectAttr(int,LicenseMagic, LicenseMagic);                          // 授权魔法值
   ObjectAttr(int,LicenseAccount, LicenseAccount);                      // 授权账户
   ObjectAttr(datetime,LicenseAuthPeriod, LicenseAuthPeriod);           // 授权日期 
   ObjectAttr(string,LicenseAuthServer, LicenseAuthServer);             // 授权服务器
   ObjectAttr(string,LicenseCurrencyPairs, LicenseCurrencyPairs);       // 授权货币对
   ObjectAttr(datetime,CompileTime, CompileTime);                       // 编译日期 

public:
   bool              check()
     {
     
         if (m_LicenseCode == 0) {
            MessageBox("授权码不能为0");
            return false;
         }
         
         if (m_LicenseMagic == 0) {
            MessageBox("授权魔法值不能为0");
            return false;
         }
         
         if (m_LicenseAuthPeriod < TimeCurrent()) {
             MessageBox("授权日期不能小于当前时间");
             return false;
         }
         return true;
     }
};



class GuoJiaLicense: public Script
{
   public:
      GuoJiaParam *m_params;

   public:
      GuoJiaLicense(GuoJiaParam *params): m_params(params) {
      }
      
      ~GuoJiaLicense() {
      }
   
      void              main() {
         string file_name = IntegerToString(m_params.getLicenseCode()) + ".license";
         
         if (File::exist(file_name, false)) {
            MessageBox("授权码 licensecode 已存在, 不覆盖生成");
            return;
         }
         
         BinaryFile license_file(file_name, FILE_WRITE);
         
         //string license_start = "LICENSESTART";
         
         //license_file.writeString(license_start, StringBufferLen(license_start));
         
         license_file.writeInteger(m_params.getLicenseCode(), 4);
         license_file.writeInteger(m_params.getLicenseMagic(), 4);
         license_file.writeInteger(m_params.getLicenseAccount(), 4);
         license_file.writeLong(m_params.getLicenseAuthPeriod());
         
         string server_str = m_params.getLicenseAuthServer();
         license_file.writeInteger(StringBufferLen(server_str), 4);
         if (StringBufferLen(server_str) > 0)
         {
            license_file.writeString(server_str, StringBufferLen(server_str));
         }
         
         string currencypairs_str = m_params.getLicenseCurrencyPairs();
         license_file.writeInteger(StringBufferLen(currencypairs_str), 4);
         if (StringBufferLen(currencypairs_str) > 0)
         {
            license_file.writeString(currencypairs_str, StringBufferLen(currencypairs_str));
         }
         
         
         //string license_end = "LICENSEEND";
         //license_file.writeString(license_end, StringBufferLen(license_end));
         
         license_file.flush();
      }
};


BEGIN_INPUT(GuoJiaParam)
INPUT(int,LicenseCode, 10001);                              // 授权码
INPUT(int,LicenseMagic, 1000001);                           // 授权魔法值
INPUT(int,LicenseAccount, 0);                               // 授权账户
INPUT(datetime,LicenseAuthPeriod, D'2024.01.01');           // 授权日期 
INPUT(string,LicenseAuthServer, "");                        // 授权服务器
INPUT(string,LicenseCurrencyPairs, "XAUUSD");               // 授权货币对
INPUT(datetime,CompileTime, __DATETIME__);                  // 编译日期 
END_INPUT

DECLARE_SCRIPT(GuoJiaLicense,true);