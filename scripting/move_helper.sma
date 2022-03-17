#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#define TASK_REDIRECT 55151
#define TASK_CHAT_MESSAGE 55152
#define TASK_DHUD_OUTPUT 55153
#define TASK_DHUD_MESSAGE 55154

new mh_redirect, mh_redirect_ip[32], Float:mh_redirect_delay
new mh_stop_movements
new mh_blind
new mh_chat_message, Float:mh_chat_message_delay, Float:mh_chat_message_interval, mh_chat_message_text[128]
new mh_dhud_message, mh_dhud_message_aod, Float:mh_dhud_message_delay, mh_dhud_coord[32], Float:mh_dhud_fcoord[2], mh_dhud_colors[32], mh_dhud_icolors[3], mh_dhud_message_text[128]

public plugin_init()
{
	register_plugin("Move Helper", "22.03.05", "Oli")

	bind_pcvar_num(create_cvar(
		"mh_redirect", // Квар
		"0", // Значение по умолчанию
		.has_min = true,
		.min_val = 0.0,
		.has_max = true,
		.max_val = 1.0,
		.description = "Производить ли редирект через client_cmd на IP в кваре mh_redirect_ip? (1 - да, 0 - нет)^nВнимание: это ЗАПРЕЩЕНО всеми мониторингами!"
	), mh_redirect)

	bind_pcvar_string(create_cvar(
		"mh_redirect_ip", // Квар
		"127.0.0.1:27015", // Значение по умолчанию
		.description = "Если mh_redirect = 1^nАйпи, на который будет произведён редирект"
	), mh_redirect_ip, charsmax(mh_redirect_ip))

	bind_pcvar_float(create_cvar(
		"mh_redirect_delay", // Квар
		"5.0", // Значение по умолчанию
		.has_min = true,
		.min_val = 0.0,
		.has_max = true,
		.max_val = 3600.0,
		.description = "Если mh_redirect = 1^nВремя после подключения до начала редиректа (0.0 - мгновенно)"
	), mh_redirect_delay)

	bind_pcvar_num(create_cvar(
		"mh_stop_movements", // Квар
		"0", // Значение по умолчанию
		.has_min = true,
		.min_val = 0.0,
		.has_max = true,
		.max_val = 1.0,
		.description = "Запретить передвижение игрокам? (1 - да, 0 - нет)"
	), mh_stop_movements)

	bind_pcvar_num(create_cvar(
		"mh_blind", // Квар
		"0", // Значение по умолчанию
		.has_min = true,
		.min_val = 0.0,
		.has_max = true,
		.max_val = 1.0,
		.description = "Затемнять экран игрокам? (1 - да, 0 - нет)"
	), mh_blind)

	bind_pcvar_num(create_cvar(
		"mh_chat_message", // Квар
		"1", // Значение по умолчанию
		.has_min = true,
		.min_val = 0.0,
		.has_max = true,
		.max_val = 1.0,
		.description = "Выводить ли текст mh_chat_message_text в чат? (1 - да, 0 - нет)"
	), mh_chat_message)

	bind_pcvar_float(create_cvar(
		"mh_chat_message_delay", // Квар
		"5.0", // Значение по умолчанию
		.has_min = true,
		.min_val = 0.0,
		.has_max = true,
		.max_val = 3600.0,
		.description = "Если mh_chat_message = 1^nЗадержка перед выводом сообщения, после подключения к серверу (0.0 - мгновенно)"
	), mh_redirect_delay)

	bind_pcvar_float(create_cvar(
		"mh_chat_message_interval", // Квар
		"5.0", // Значение по умолчанию
		.has_min = true,
		.min_val = 0.0,
		.has_max = true,
		.max_val = 3600.0,
		.description = "Если mh_chat_message = 1^nИнтервал между следующим выводом этого сообщения(0.0 - выведет сообщение только один раз)"
	), mh_chat_message_interval)

	bind_pcvar_string(create_cvar(
		"mh_chat_message_text", // Квар
		"!g[Перенаправление] !yК сожалению мы переехали на новый IP адрес!", // Значение по умолчанию
		.description = "Если mh_chat_message = 1^nСообщение, выводимое в чат^nЦвета: !g - зелёный, !t - команды, !y - жёлтый"
	), mh_chat_message_text, charsmax(mh_chat_message_text))

	bind_pcvar_num(create_cvar(
		"mh_dhud_message", // Квар
		"1", // Значение по умолчанию
		.has_min = true,
		.min_val = 0.0,
		.has_max = true,
		.max_val = 1.0,
		.description = "Выводить ли текст mh_dhud_message_text в дхуд? (1 - да, 0 - нет)"
	), mh_dhud_message)

	bind_pcvar_num(create_cvar(
		"mh_dhud_message_aod", // Квар
		"1", // Значение по умолчанию
		.has_min = true,
		.min_val = 0.0,
		.has_max = true,
		.max_val = 1.0,
		.description = "Постоянный показ dhud на экране, без исчезновения (1 - да, 0 - нет)"
	), mh_dhud_message_aod)

	bind_pcvar_float(create_cvar(
		"mh_dhud_message_delay", // Квар
		"5.0", // Значение по умолчанию
		.has_min = true,
		.min_val = 0.0,
		.has_max = true,
		.max_val = 3600.0,
		.description = "Задержка перед выводом сообщения в dhud, после подключения к серверу (0.0 - мгновенно)"
	), mh_dhud_message_delay)

	bind_pcvar_string(create_cvar(
		"mh_dhud_coord", // Квар
		"-1.0 0.35", // Значение по умолчанию
		.description = "Координаты dhud в формате x y"
	), mh_dhud_coord, charsmax(mh_dhud_coord))

	bind_pcvar_string(create_cvar(
		"mh_dhud_colors", // Квар
		"255 255 255", // Значение по умолчанию
		.description = "Цвет dhud в формате RGB"
	), mh_dhud_colors, charsmax(mh_dhud_colors))

	bind_pcvar_string(create_cvar(
		"mh_dhud_message_text", // Квар
		"!g[Перенаправление] !yК сожалению мы переехали на новый IP адрес!", // Значение по умолчанию
		.description = "Сообщение, выводимое в dhud"
	), mh_dhud_message_text, charsmax(mh_dhud_message_text))

	AutoExecConfig()

	RegisterHam(Ham_Spawn, "player", "fw_Ham_Spawn_post", 1)
}

public OnConfigsExecuted()
{
	if (mh_chat_message)
	{
		replace_all(mh_chat_message_text, charsmax(mh_chat_message_text), "!g", "^4")
		replace_all(mh_chat_message_text, charsmax(mh_chat_message_text), "!y", "^1")
		replace_all(mh_chat_message_text, charsmax(mh_chat_message_text), "!t", "^3")
	}

	if (mh_dhud_message)
	{
		new szLeft[32], szRight[32]
		strtok(mh_dhud_colors, szLeft, charsmax(szLeft), szRight, charsmax(szRight))
		mh_dhud_icolors[0] = str_to_num(szLeft)
		strtok(szRight, szLeft, charsmax(szLeft), szRight, charsmax(szRight))
		mh_dhud_icolors[1] = str_to_num(szLeft)
		mh_dhud_icolors[2] = str_to_num(szRight)

		strtok(mh_dhud_coord, szLeft, charsmax(szLeft), szRight, charsmax(szRight))
		mh_dhud_fcoord[0] = str_to_float(szLeft)
		mh_dhud_fcoord[1] = str_to_float(szRight)
	}
}

public client_connect(id)
{	
	if (mh_redirect && mh_redirect_delay <= 0.0)
		redirect(id)
}

public client_putinserver(id)
{
	if (mh_redirect)
		set_task(mh_redirect_delay < 0.1 ? 0.1 : mh_redirect_delay, "redirect", id+TASK_REDIRECT)

	if (mh_chat_message)
		set_task(mh_chat_message_delay < 0.1 ? 0.1 : mh_chat_message_delay, "message", id+TASK_CHAT_MESSAGE)

	if (mh_dhud_message)
		set_task(mh_dhud_message_delay < 0.1 ? 0.1 : mh_dhud_message_delay, "dhud_output", id+TASK_DHUD_OUTPUT)

	if (mh_blind)
		amx_blind(id)
}

public fw_Ham_Spawn_post(id)
{
	if (!is_user_alive(id))
		return
	
	if (mh_blind)
		amx_blind(id)

	if (mh_stop_movements)
		set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN)
}

public redirect(taskid)	
{
	new id
	if (taskid > TASK_REDIRECT)
		id = taskid-TASK_REDIRECT
	else
		id = taskid

	if (!is_user_connected(id))
		return

	client_cmd(id, "connect %s", mh_redirect_ip)
}

public message(taskid)
{
	new id = taskid-TASK_CHAT_MESSAGE
	if (!is_user_connected(id))
		return

	if (!mh_chat_message_text[0])
		return

	client_print_color(id, print_team_default, "%s", mh_chat_message_text)

	if (mh_chat_message_interval > 0.0)
		set_task(mh_chat_message_interval < 0.1 ? 0.1 : mh_chat_message_interval, "message", taskid)
}

public dhud_output(taskid)
{
	new id = taskid-TASK_DHUD_OUTPUT
	if (!is_user_connected(id))
		return

	if (mh_dhud_message_aod)
		set_task(0.8, "dhud", id+TASK_DHUD_MESSAGE, .flags="b")
	else
		set_task(0.8, "dhud", id+TASK_DHUD_MESSAGE)
}

public dhud(taskid)
{
	new id = taskid-TASK_DHUD_MESSAGE
	if (!is_user_connected(id))
		return

	if (!mh_dhud_message_text[0])
		return

	set_dhudmessage(mh_dhud_icolors[0], mh_dhud_icolors[1], mh_dhud_icolors[2], mh_dhud_fcoord[0], mh_dhud_fcoord[1], 0, 0.0, 3.0, 2.0, 1.0)
	show_dhudmessage(id, "%s", mh_dhud_message_text)
}

public amx_blind(id)
{ 
	if (!is_user_connected(id))
		return

	static gmsgFade
	if (!gmsgFade)
		gmsgFade = get_user_msgid("ScreenFade")

	message_begin(MSG_ONE, gmsgFade, {0,0,0}, id) // use the magic #1 for "one client" 
	write_short(1<<0) // fade lasts this long duration 
	write_short(1<<0) // fade lasts this long hold time 
	write_short(1<<2) // fade type HOLD 
	write_byte(0) // fade red 
	write_byte(0) // fade green 
	write_byte(0) // fade blue  
	write_byte(255) // fade alpha  
	message_end() 
}