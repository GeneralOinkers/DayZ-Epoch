private ["_part_out","_part_in","_qty_out","_qty_in","_qty","_buy_o_sell","_textPartIn","_textPartOut","_bos","_needed","_started","_finished","_animState","_isMedic","_total_parts_out","_abort","_removed","_activatingPlayer","_traderID","_done","_actualMags"];
// [part_out,part_in, qty_out, qty_in,];

if (DZE_ActionInProgress) exitWith {localize "str_epoch_player_103" call dayz_rollingMessages;};
DZE_ActionInProgress = true;

_activatingPlayer = player;

_part_out = (_this select 3) select 0;
_part_in = (_this select 3) select 1;
_qty_out = (_this select 3) select 2;
_qty_in = (_this select 3) select 3;
_buy_o_sell = (_this select 3) select 4;
_textPartIn = (_this select 3) select 5;
_textPartOut = (_this select 3) select 6;
_traderID = (_this select 3) select 7;

_bos = 0;
if(_buy_o_sell == "sell") then {
	_bos = 1;
};

_abort = false;

// perform number of total trades
r_autoTrade = true;
while {r_autoTrade} do {

	_removed = 0;

	// check if current magazine count is greater than 20
	_actualMags = {!(_x in MeleeMagazines)} count (magazines player);
	if (_actualMags > 20) exitWith {localize "str_player_24" call dayz_rollingMessages; r_autoTrade = false};
	
	_canAfford = false;
	if(_bos == 1) then {
		
		//sell
		_qty = {_x == _part_in} count magazines player;
		if (_qty >= _qty_in) then {
			_canAfford = true;
		};

	} else {
		
		//buy
		_trade_total = [[_part_in,_qty_in]] call epoch_itemCost;
		_total_currency = call epoch_totalCurrency;
		_return_change = _total_currency - _trade_total; 
		if (_return_change >= 0) then {
			_canAfford = true;
		};
	};
	
	if(!_canAfford) exitWith {
		_qty = {_x == _part_in} count magazines player;
		_needed =  _qty_in - _qty;
		format[localize "str_epoch_player_184",_needed,_textPartIn] call dayz_rollingMessages;
		r_autoTrade = false
	};
	
	localize "str_epoch_player_105" call dayz_rollingMessages;

	["Working",0,[3,2,8,0]] call dayz_NutritionSystem;
	player playActionNow "Medic";
	
	//_dis=20;
	//_sfx = "repair";
	//[player,_sfx,0,false,_dis] call dayz_zombieSpeak;
	//[player,_dis,true,(getPosATL player)] spawn player_alertZombies;

	r_interrupt = false;
	_animState = animationState player;
	r_doLoop = true;
	_started = false;
	_finished = false;
	
	while {r_doLoop} do {
		_animState = animationState player;
		_isMedic = ["medic",_animState] call fnc_inString;
		if (_isMedic) then {
			_started = true;
		};
		if (_started && !_isMedic) then {
			r_doLoop = false;
			_finished = true;
		};
		if (r_interrupt) then {
			r_doLoop = false;
		};
		uiSleep 0.1;
	};
	r_doLoop = false;

	if (!_finished) exitWith { 
		r_interrupt = false;
		if (vehicle player == player) then {
			[objNull, player, rSwitchMove,""] call RE;
			player playActionNow "stop";
		};
		localize "str_epoch_player_106" call dayz_rollingMessages;
	};

	if (_finished) then {

		//diag_log format["DEBUG TRADER DONE?: %1", _canAfford];
		
		// Continue with trade.
		if (isNil "_part_in") then { _part_in = "Unknown Item" };
		if(_bos == 1) then {
			// Selling
			PVDZE_obj_Trade = [_activatingPlayer,_traderID,_bos,_part_in,inTraderCity,_part_out,_qty_out];
		} else {
			// Buying
			PVDZE_obj_Trade = [_activatingPlayer,_traderID,_bos,_part_out,inTraderCity,_part_in,_qty_in];
		};
		publicVariableServer  "PVDZE_obj_Trade";

		if(_bos == 0) then {
			// only wait for result when buying
			waitUntil {!isNil "dayzTradeResult"};
			if(dayzTradeResult == "PASS") then {
				_done = [[[_part_in,_qty_in]],0] call epoch_returnChange;
				if (_done) then {
					for "_x" from 1 to _qty_out do {
						player addMagazine _part_out;
					};
					format[localize "str_epoch_player_186",_qty_in,_textPartIn,_qty_out,_textPartOut] call dayz_rollingMessages;
				};
			} else {
				_abort = true;
				format[localize "str_epoch_player_183",_textPartOut] call dayz_rollingMessages;
			};
		} else {
			_part_inClass =  configFile >> "CfgMagazines" >> _part_in;
			_removed = _removed + ([player,_part_inClass,_qty_in] call BIS_fnc_invRemove);
			if (_removed == _qty_in) then {
				[[[_part_out,_qty_out]],1] call epoch_returnChange;
			};
			format[localize "str_epoch_player_186",_qty_in,_textPartIn,_qty_out,_textPartOut] call dayz_rollingMessages;
		};
		dayzTradeResult = nil;
	};
	if(_abort) exitWith {r_autoTrade = false};
	
	uiSleep 1;
};

DZE_ActionInProgress = false;
