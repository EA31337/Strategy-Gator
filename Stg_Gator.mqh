/**
 * @file
 * Implements Gator strategy based on the Gator oscillator.
 */

// User input params.
INPUT string __Gator_Parameters__ = "-- Gator strategy params --";  // >>> GATOR <<<
INPUT float Gator_LotSize = 0;                                      // Lot size
INPUT int Gator_SignalOpenMethod = 0;                               // Signal open method (-4-4)
INPUT float Gator_SignalOpenLevel = 0.0f;                           // Signal open level
INPUT int Gator_SignalOpenFilterMethod = 1;                         // Signal open filter method
INPUT int Gator_SignalOpenBoostMethod = 0;                          // Signal open boost method
INPUT int Gator_SignalCloseMethod = 0;                              // Signal close method (-4-4)
INPUT float Gator_SignalCloseLevel = 0.0f;                          // Signal close level
INPUT int Gator_PriceStopMethod = 0;                                // Price stop method
INPUT float Gator_PriceStopLevel = 0;                               // Price stop level
INPUT int Gator_TickFilterMethod = 1;                               // Tick filter method
INPUT float Gator_MaxSpread = 4.0;                                  // Max spread to trade (pips)
INPUT short Gator_Shift = 2;                                        // Shift
INPUT int Gator_OrderCloseTime = -20;                               // Order close time in mins (>0) or bars (<0)
INPUT string __Gator_Indi_Gator_Parameters__ =
    "-- Gator strategy: Gator indicator params --";                   // >>> Gator strategy: Gator indicator <<<
INPUT int Gator_Indi_Gator_Period_Jaw = 6;                            // Jaw Period
INPUT int Gator_Indi_Gator_Period_Teeth = 10;                         // Teeth Period
INPUT int Gator_Indi_Gator_Period_Lips = 8;                           // Lips Period
INPUT int Gator_Indi_Gator_Shift_Jaw = 5;                             // Jaw Shift
INPUT int Gator_Indi_Gator_Shift_Teeth = 7;                           // Teeth Shift
INPUT int Gator_Indi_Gator_Shift_Lips = 5;                            // Lips Shift
INPUT ENUM_MA_METHOD Gator_Indi_Gator_MA_Method = (ENUM_MA_METHOD)2;  // MA Method
INPUT ENUM_APPLIED_PRICE Gator_Indi_Gator_Applied_Price = (ENUM_APPLIED_PRICE)3;  // Applied Price
INPUT int Gator_Indi_Gator_Shift = 0;                                             // Shift

// Structs.

// Defines struct with default user indicator values.
struct Indi_Gator_Params_Defaults : GatorParams {
  Indi_Gator_Params_Defaults()
      : GatorParams(::Gator_Indi_Gator_Period_Jaw, ::Gator_Indi_Gator_Shift_Jaw, ::Gator_Indi_Gator_Period_Teeth,
                    ::Gator_Indi_Gator_Shift_Teeth, ::Gator_Indi_Gator_Period_Lips, ::Gator_Indi_Gator_Shift_Lips,
                    ::Gator_Indi_Gator_MA_Method, ::Gator_Indi_Gator_Applied_Price, ::Gator_Indi_Gator_Shift) {}

} indi_gator_defaults;

// Defines struct with default user strategy values.
struct Stg_Gator_Params_Defaults : StgParams {
  Stg_Gator_Params_Defaults()
      : StgParams(::Gator_SignalOpenMethod, ::Gator_SignalOpenFilterMethod, ::Gator_SignalOpenLevel,
                  ::Gator_SignalOpenBoostMethod, ::Gator_SignalCloseMethod, ::Gator_SignalCloseLevel,
                  ::Gator_PriceStopMethod, ::Gator_PriceStopLevel, ::Gator_TickFilterMethod, ::Gator_MaxSpread,
                  ::Gator_Shift, ::Gator_OrderCloseTime) {}
} stg_gator_defaults;

// Struct to define strategy parameters to override.
struct Stg_Gator_Params : StgParams {
  GatorParams iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_Gator_Params(GatorParams &_iparams, StgParams &_sparams)
      : iparams(indi_gator_defaults, _iparams.tf), sparams(stg_gator_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_Gator : public Strategy {
 public:
  Stg_Gator(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_Gator *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    GatorParams _indi_params(indi_gator_defaults, _tf);
    StgParams _stg_params(stg_gator_defaults);
#ifdef __config__
    SetParamsByTf<GatorParams>(_indi_params, _tf, indi_gator_m1, indi_gator_m5, indi_gator_m15, indi_gator_m30,
                               indi_gator_h1, indi_gator_h4, indi_gator_h8);
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_gator_m1, stg_gator_m5, stg_gator_m15, stg_gator_m30, stg_gator_h1,
                             stg_gator_h4, stg_gator_h8);
#endif
    // Initialize indicator.
    GatorParams gator_params(_indi_params);
    _stg_params.SetIndicator(new Indi_Gator(_indi_params));
    // Initialize strategy parameters.
    _stg_params.GetLog().SetLevel(_log_level);
    _stg_params.SetMagicNo(_magic_no);
    _stg_params.SetTf(_tf, _Symbol);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_Gator(_stg_params, "Gator");
    return _strat;
  }

  /**
   * Check if Gator Oscillator is on buy or sell.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_Gator *_indi = Data();
    bool _is_valid = _indi[_shift].IsValid() && _indi[_shift + 1].IsValid() && _indi[_shift + 2].IsValid();
    bool _result = _is_valid;
    if (_is_valid) {
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          // Buy: if the indicator is increasing.
          _result &= _indi.IsIncreasing(2, LINE_UPPER_HISTOGRAM, _shift);
          _result &= _indi.IsDecreasing(2, LINE_LOWER_HISTOGRAM, _shift);
          _result &= _indi.IsIncByPct(_level, LINE_UPPER_HISTOGRAM, _shift, 2);
          _result &= _indi.IsDecByPct(-_level, LINE_LOWER_HISTOGRAM, _shift, 2);
          if (_result && _method != 0) {
            if (METHOD(_method, 0)) _result &= _indi.IsIncreasing(2, LINE_LOWER_HISTOGRAM, _shift + 3);
            if (METHOD(_method, 1)) _result &= _indi.IsIncreasing(2, LINE_LOWER_HISTOGRAM, _shift + 5);
          }
          break;
        case ORDER_TYPE_SELL:
          // Sell: if the indicator is decreasing.
          _result &= _indi.IsDecreasing(2, LINE_UPPER_HISTOGRAM, _shift);
          _result &= _indi.IsIncreasing(2, LINE_LOWER_HISTOGRAM, _shift);
          _result &= _indi.IsDecByPct(-_level, LINE_UPPER_HISTOGRAM, _shift, 2);
          _result &= _indi.IsIncByPct(_level, LINE_LOWER_HISTOGRAM, _shift, 2);
          if (_result && _method != 0) {
            if (METHOD(_method, 0)) _result &= _indi.IsDecreasing(2, LINE_UPPER_HISTOGRAM, _shift + 3);
            if (METHOD(_method, 1)) _result &= _indi.IsDecreasing(2, LINE_UPPER_HISTOGRAM, _shift + 5);
          }
          break;
      }
    }
    return _result;
  }

  /**
   * Gets price stop value for profit take or stop loss.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_Gator *_indi = Data();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    switch (_method) {
      case 1: {
        int _bar_count1 = (int)_level * (int)_indi.GetLipsPeriod();
        _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count1))
                                 : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count1));
        break;
      }
      case 2: {
        int _bar_count2 = (int)_level * (int)_indi.GetTeethShift();
        _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count2))
                                 : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count2));
        break;
      }
      case 3: {
        int _bar_count3 = (int)_level * (int)_indi.GetJawPeriod();
        _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count3))
                                 : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count3));
        break;
      }
    }
    return (float)_result;
  }
};
