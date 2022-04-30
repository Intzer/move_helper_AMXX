#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#if AMXX_VERSION_NUM < 183
	#define AMXX_182
	#include <colorchat>
	#define client_disconnected client_disconnect
#endif

#define TASK_REDIRECT 55151
#define TASK_CHAT_MESSAGE 55152
#define TASK_DHUD_MESSAGE 55153

new mh_redirect, mh_redirect_ip[32], Float:mh_redirect_delay
new mh_stop_movements
new mh_blind
new mh_chat_message, Float:mh_chat_message_interval, mh_chat_message_text[128]
new mh_dhud_message, mh_dhud_coord[32], Float:mh_dhud_fcoord[2], mh_dhud_colors[32], mh_dhud_icolors[3], mh_dhud_message_text[128]

public plugin_init()
{
	register_plugin("Move Helper", "30.04.22", "Oli")
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", true)

	#if define AMXX_182
		register_cvar("mh_redirect", "0")
		register_cvar("mh_redirect_ip", "127.0.0.1:27015")
		register_cvar("mh_redirect_delay", "5.0")
		register_cvar("mh_stop_movements", "1")
		register_cvar("mh_blind", "1")
		register_cvar("mh_chat_message", "1")
		register_cvar("mh_chat_message_interval", "5.0")
		register_cvar("mh_chat_message_text", "!g[Перенаправление] !yК сожалению мы переехали на новый IP адрес!")
		register_cvar("mh_dhud_message", "1")
		register_cvar("mh_dhud_coord", "-1.0 0.35")
		register_cvar("mh_dhud_colors", "255 255 255")
		register_cvar("mh_dhud_message_text", "[Перенаправление] К сожалению мы переехали на новый IP адрес!")

		set_task(3.0, "OnConfigsExecuted")
	#else
		bind_pcvar_num(create_cvar(
			"mh_redirect",
			"0",
			.description = "Производить ли редирект через client_cmd на IP в кваре mh_redirect_ip? (1 - да, 0 - нет)^nВнимание: это ЗАПРЕЩЕНО всеми мониторингами!"
		), mh_redirect)

		bind_pcvar_string(create_cvar(
			"mh_redirect_ip",
			"127.0.0.1:27015",
			.description = "Айпи, на который будет произведён прямой редирект, если включена такая настройка"
		), mh_redirect_ip, charsmax(mh_redirect_ip))

		bind_pcvar_float(create_cvar(
			"mh_redirect_delay",
			"5.0",
			.description = "Если mh_redirect = 1^nВремя после подключения до начала редиректа (0.0 - мгновенно)"
		), mh_redirect_delay)

		bind_pcvar_num(create_cvar(
			"mh_stop_movements",
			"1",
			.description = "Запретить передвижение игрокам? (1 - да, 0 - нет)"
		), mh_stop_movements)

		bind_pcvar_num(create_cvar(
			"mh_blind",
			"1",
			.description = "Затемнять экран игрокам? (1 - да, 0 - нет)"
		), mh_blind)

		bind_pcvar_num(create_cvar(
			"mh_chat_message",
			"1",
			.description = "Выводить ли текст mh_chat_message_text в чат? (1 - да, 0 - нет)"
		), mh_chat_message)

		bind_pcvar_float(create_cvar(
			"mh_chat_message_interval",
			"5.0",
			.description = "Если mh_chat_message = 1^nИнтервал между следующим выводом этого сообщения(0.0 - выведет сообщение только один раз)"
		), mh_chat_message_interval)

		bind_pcvar_string(create_cvar(
			"mh_chat_message_text",
			"!g[Перенаправление] !yК сожалению мы переехали на новый IP адрес!",
			.description = "Если mh_chat_message = 1^nСообщение, выводимое в чат^nЦвета: !g - зелёный, !t - команды, !y - жёлтый"
		), mh_chat_message_text, charsmax(mh_chat_message_text))

		bind_pcvar_num(create_cvar(
			"mh_dhud_message",
			"1",
			.description = "Выводить ли текст mh_dhud_message_text в дхуд? (1 - да, 0 - нет)"
		), mh_dhud_message)

		bind_pcvar_string(create_cvar(
			"mh_dhud_coord",
			"-1.0 0.35",
			.description = "Координаты dhud в формате x y"
		), mh_dhud_coord, charsmax(mh_dhud_coord))

		bind_pcvar_string(create_cvar(
			"mh_dhud_colors",
			"255 255 255",
			.description = "Цвет dhud в формате RGB"
		), mh_dhud_colors, charsmax(mh_dhud_colors))

		bind_pcvar_string(create_cvar(
			"mh_dhud_message_text",
			"[Перенаправление] К сожалению мы переехали на новый IP адрес!",
			.description = "Сообщение, выводимое в dhud"
		), mh_dhud_message_text, charsmax(mh_dhud_message_text))

		AutoExecConfig()
	#endif
}

public OnConfigsExecuted()
{
	#if defined AMXX_182
		register_cvar("mh_redirect", "0")
		register_cvar("mh_redirect_ip", "127.0.0.1:27015")
		register_cvar("mh_redirect_delay", "5.0")
		register_cvar("mh_stop_movements", "1")
		register_cvar("mh_blind", "1")
		register_cvar("mh_chat_message", "1")
		register_cvar("mh_chat_message_interval", "5.0")
		register_cvar("mh_chat_message_text", "!g[Перенаправление] !yК сожалению мы переехали на новый IP адрес!")
		register_cvar("mh_dhud_message", "1")
		register_cvar("mh_dhud_coord", "-1.0 0.35")
		register_cvar("mh_dhud_colors", "255 255 255")
		register_cvar("mh_dhud_message_text", "[Перенаправление] К сожалению мы переехали на новый IP адрес!")

		mh_redirect = get_cvar_num("mh_redirect")
		get_cvar_string("mh_redirect_ip", mh_redirect_ip, charsmax(mh_redirect_ip))
		mh_redirect_delay = get_cvar_float("mh_redirect_delay")
		mh_stop_movements = get_cvar_num("mh_stop_movements")
		mh_blind = get_cvar_num("mh_blind")
		mh_chat_message = get_cvar_num("mh_chat_message")
		mh_chat_message_interval = get_cvar_float("mh_chat_message_interval")
		get_cvar_string("mh_chat_message_text", mh_chat_message_text, charsmax(mh_chat_message_text))
		mh_dhud_message = get_cvar_num("mh_dhud_message")
		get_cvar_string("mh_dhud_coord", mh_dhud_coord, charsmax(mh_dhud_coord))
		get_cvar_string("mh_dhud_colors", mh_dhud_colors, charsmax(mh_dhud_colors))
		get_cvar_string("mh_dhud_message_text", mh_dhud_message_text, charsmax(mh_dhud_message_text))
	#endif

	if (mh_chat_message)
	{
		replace_all(mh_chat_message_text, charsmax(mh_chat_message_text), "!g", "^4")
		replace_all(mh_chat_message_text, charsmax(mh_chat_message_text), "!y", "^1")
		replace_all(mh_chat_message_text, charsmax(mh_chat_message_text), "!t", "^3")

		if (mh_chat_message_interval < 0.1)
			mh_chat_message_interval = 0.1
	}

	if (mh_dhud_message)
	{
		new szLeft[32]
		strtok(mh_dhud_colors, szLeft, charsmax(szLeft), mh_dhud_colors, charsmax(mh_dhud_colors))
		mh_dhud_icolors[0] = str_to_num(szLeft)
		strtok(mh_dhud_colors, szLeft, charsmax(szLeft), mh_dhud_colors, charsmax(mh_dhud_colors))
		mh_dhud_icolors[1] = str_to_num(szLeft)
		mh_dhud_icolors[2] = str_to_num(mh_dhud_colors)

		strtok(mh_dhud_coord, szLeft, charsmax(szLeft), mh_dhud_coord, charsmax(mh_dhud_coord))
		mh_dhud_fcoord[0] = str_to_float(szLeft)
		mh_dhud_fcoord[1] = str_to_float(mh_dhud_coord)
	}
}

public client_connect(id)
{	
	if (mh_redirect && mh_redirect_delay < 0.1)
		make_redirect(id+TASK_REDIRECT)
}

public client_putinserver(id)
{
	if (mh_redirect)
		set_task(mh_redirect_delay, "make_redirect", id+TASK_REDIRECT)

	if (mh_chat_message)
		set_task(mh_chat_message_interval, "message_output", id+TASK_CHAT_MESSAGE, .flags = "b")

	if (mh_dhud_message)
		set_task(0.8, "dhud_output", id+TASK_DHUD_MESSAGE, .flags = "b")

	if (mh_blind)
		util_blind(id)
}

public client_disconnected(id)
{
	remove_task(id+TASK_REDIRECT)
	remove_task(id+TASK_DHUD_MESSAGE)
	remove_task(id+TASK_CHAT_MESSAGE)
}

public fw_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id))
		return HAM_IGONRED
	
	if (mh_blind)
		util_blind(id)

	if (mh_stop_movements)
		set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN)

	return HAM_IGONRED
}

public make_redirect(taskid)	
{
	new id = taskid-TASK_REDIRECT
	client_cmd(id, "connect %s", mh_redirect_ip)
}

public message_output(taskid)
{
	new id = taskid-TASK_CHAT_MESSAGE

	client_print_color(id, 0, "%s", mh_chat_message_text)
}

public dhud_output(taskid)
{
	new id = taskid-TASK_DHUD_MESSAGE

	set_dhudmessage(mh_dhud_icolors[0], mh_dhud_icolors[1], mh_dhud_icolors[2], mh_dhud_fcoord[0], mh_dhud_fcoord[1], 0, 0.0, 3.0, 2.0, 1.0)
	show_dhudmessage(id, "%s", mh_dhud_message_text)
}

public util_blind(id)
{ 
	static g_MsgScreenfade
	if (!g_MsgScreenfade)
		g_MsgScreenfade = get_user_msgid("ScreenFade")

	message_begin(MSG_ONE, g_MsgScreenfade, {0,0,0}, id)	// use the magic #1 for "one client" 
	write_short(1<<0)	// fade lasts this long duration 
	write_short(1<<0)	// fade lasts this long hold time 
	write_short(1<<2)	// fade type HOLD 
	write_byte(0)		// fade red 
	write_byte(0)		// fade green 
	write_byte(0)		// fade blue  
	write_byte(255)		// fade alpha  
	message_end() 
}