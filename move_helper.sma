#include <amxmodx>

/* ~ [ Настройки ] ~ */
// Редирект
#define REDIRECT false					// Включён ли редирект на IP, указанный в REDIRECT_IP
#define REDIRECT_IP "127.0.0.1:27015"	// IP на который будет совершён редирект
#define REDIRECT_TIME 3.0				// Время после подключения до начала редиректа (0.0 - мгновенно)

// Перемещение
#define STOP_MOVEMENTS true			// Запретить передвижение игрокам

// Потемнение экрана
#define BLIND true					// Затемнять экран игрокам
#define BLIND_DELAY 0.0				// Задержка перед затемнением экрана (0.0 - мгновенно)

// Сообщение в чат
#define CHAT_MESSAGE true			// Выводить ли сообщение в чат 
#define CHAT_MESSAGE_DELAY 5.0		// Задержка перед выводом сообщения, после подключения к серверу
#define CHAT_MESSAGE_INTERVAL 3.0		// Интервал между следующим выводом этого сообщения(0.0 - выведет сообщение только один раз)
// Текст, который будет выводится в чат (^4 - зелёный, ^3 - цвет команды, ^1 - обычный)
new const CHAT_MESSAGE_TEXT[] = "^4[Перенаправление] ^1К сожалению мы переехали на новый IP адрес!"

// Сообщение по центру экрана (dhud)
#define DHUD_MESSAGE true			// Выводить ли DHUD сообщение на экран
#define DHUD_MESSAGE_AOD true		// Если true, то сообщение будет на экране постоянно, иначе - исчезнет после показа
#define DHUD_MESSAGE_DELAY 5.0		// Задержка перед выводом DHUD сообщения, после подключения к серверу
// Текст, который будет выводится в DHUD (^4 - зелёный, ^3 - цвет команды, ^1 - обычный)
new const DHUD_MESSAGE_TEXT[] = "^4[Перенаправление] ^1К сожалению мы переехали на новый IP адрес!"
#define DHUD_COORD "-1.0 -1.0"		// Координаты DHUD (x, y). -1.0 — означает по центру координатной оси.
#define DHUD_COLOR "255 255 255"	// Цвет DHUD сообщения в формате RGB
/* ~~~~~~~~~~~~~~~~~ */

#define TASK_REDIRECT 55151
#define TASK_CHAT_MESSAGE 55152
#define TASK_DHUD_OUTPUT 55153
#define TASK_DHUD_MESSAGE 55153
#define TASK_BLIND 55154

#if DHUD_MESSAGE == true
	new Float:dhud_coord[2], dhud_color[3]
#endif

#if BLIND == true
	new gmsgFade
#endif

#if STOP_MOVEMENTS == true
	#include <fun>
	#include <hamsandwich>
#endif

public plugin_init()
{
	register_plugin("Move Helper", "22.03.05", "Oli")
	
	#if BLIND == true
		gmsgFade = get_user_msgid("ScreenFade")
	#endif

	#if BLIND == true || STOP_MOVEMENTS == true
		RegisterHam(Ham_Spawn, "player", "fw_Ham_Spawn")
	#endif
}

#if DHUD_MESSAGE == true
public plugin_precache()
{
	new szBuffer1[10], szBuffer2[10], szBuffer3[10]

	parse(DHUD_COORD, szBuffer1, charsmax(szBuffer1), szBuffer2, charsmax(szBuffer2))
	dhud_coord[0] = str_to_float(szBuffer1)
	dhud_coord[1] = str_to_float(szBuffer2)

	parse(DHUD_COLOR, szBuffer1, charsmax(szBuffer1), szBuffer2, charsmax(szBuffer2), szBuffer3, charsmax(szBuffer3))
	dhud_color[0] = str_to_num(szBuffer1)
	dhud_color[1] = str_to_num(szBuffer2)
	dhud_color[2] = str_to_num(szBuffer3)
}
#endif

public client_connect(id)
{	
	#if REDIRECT == true
		if (REDIRECT_TIME <= 0.0)
			redirect(id)
	#endif
}

public client_putinserver(id)
{
	#if REDIRECT == true
		set_task(REDIRECT_TIME < 0.1 ? 0.1 : REDIRECT_TIME, "redirect", id+TASK_REDIRECT)
	#endif

	#if CHAT_MESSAGE == true
		set_task(CHAT_MESSAGE_DELAY < 0.1 ? 0.1 : CHAT_MESSAGE_DELAY, "message", id+TASK_CHAT_MESSAGE)
	#endif

	#if DHUD_MESSAGE == true
		set_task(DHUD_MESSAGE_DELAY < 0.1 ? 0.1 : DHUD_MESSAGE_DELAY, "dhud_output", id+TASK_DHUD_OUTPUT)
	#endif

	#if BLIND == true
		amx_blind(id)
	#endif
}

#if STOP_MOVEMENTS == true || BLIND == true
public fw_Ham_Spawn(id)
{
	#if BLIND == true
		amx_blind(id)
	#endif

	#if STOP_MOVEMENTS == true
		set_user_maxspeed(id, 0.0)
	#endif
}
#endif

#if REDIRECT == true
public redirect(taskid)	
{
	if (taskid > TASK_REDIRECT)
		if (!is_user_connected(taskid-TASK_REDIRECT))
			return

	client_cmd(taskid > TASK_REDIRECT ? taskid-TASK_REDIRECT : taskid, "connect %s", "REDIRECT_IP")
}
#endif

#if CHAT_MESSAGE == true
public message(taskid)
{
	if (!is_user_connected(taskid-TASK_CHAT_MESSAGE))
		return

	if (!CHAT_MESSAGE_TEXT[0])
		return

	client_print_color(taskid-TASK_CHAT_MESSAGE, print_team_default, "%s", CHAT_MESSAGE_TEXT)

	if (CHAT_MESSAGE_INTERVAL > 0.0)
		set_task(CHAT_MESSAGE_INTERVAL < 0.1 ? 0.1 : CHAT_MESSAGE_INTERVAL, "message", taskid)
}
#endif

public dhud_output(taskid)
{
	if (!is_user_connected(taskid-TASK_DHUD_OUTPUT))
		return

	#if DHUD_MESSAGE_AOD == true
		set_task(0.8, "dhud", taskid-TASK_DHUD_OUTPUT+TASK_DHUD_MESSAGE, .flags="b")
	#else
		set_task(0.8, "dhud", taskid-TASK_DHUD_OUTPUT+TASK_DHUD_MESSAGE)
	#endif
}

#if DHUD_MESSAGE == true
public dhud(taskid)
{
	if (!is_user_connected(taskid-TASK_DHUD_MESSAGE))
		return

	if (!DHUD_MESSAGE_TEXT[0])
		return

	set_dhudmessage(dhud_color[0], dhud_color[1], dhud_color[2], dhud_coord[0], dhud_coord[0], 0, 0.0, 3.0, 2.0, 1.0)
	show_dhudmessage(taskid-TASK_DHUD_MESSAGE, "%s", DHUD_MESSAGE_TEXT)
}
#endif

#if BLIND == true
public amx_blind(id)
{ 
	if (!is_user_connected(id))
		return

	if (BLIND_DELAY < 0.0)
		blind(id)
	else
		set_task(BLIND_DELAY < 0.1 ? 0.1 : BLIND_DELAY, "delay_blind", id+TASK_BLIND)
}

public delay_blind(taskid)
{
	if (!is_user_connected(taskid-TASK_BLIND))
		return

	blind(taskid-TASK_BLIND)
}

public blind(id)
{
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
#endif

