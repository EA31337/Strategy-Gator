/*
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_Gator_Params_M5 : IndiGatorParams {
  Indi_Gator_Params_M5() : IndiGatorParams(indi_gator_defaults, PERIOD_M5) {
    applied_price = (ENUM_APPLIED_PRICE)1;
    jaw_period = 10;
    jaw_shift = 8;
    lips_period = 3;
    lips_shift = 1;
    ma_method = (ENUM_MA_METHOD)2;
    shift = 0;
    teeth_period = 4;
    teeth_shift = 3;
  }
} indi_gator_m5;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Gator_Params_M5 : StgParams {
  // Struct constructor.
  Stg_Gator_Params_M5() : StgParams(stg_gator_defaults) {
    lot_size = 0;
    signal_open_method = 2;
    signal_open_level = (float)0;
    signal_open_boost = 0;
    signal_close_method = 2;
    signal_close_level = (float)0;
    price_profit_method = 60;
    price_profit_level = (float)6;
    price_stop_method = 60;
    price_stop_level = (float)6;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_gator_m5;
