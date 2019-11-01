#include <sourcemod>

public Plugin myinfo =  {
	name = "COD: Help", 
	author = "d0naciak", 
	description = "", 
	version = "1.0", 
	url = "d0naciak.pl"
};

public void OnPluginStart() {
	RegConsoleCmd("sm_help", cmd_Help);
	RegConsoleCmd("sm_pomoc", cmd_Help);
}

public Action cmd_Help(int client, int args) {
	Menu menu = new Menu(HelpMenu_Handler, MENU_ACTIONS_ALL);
	menu.SetTitle("➫ Pomoc - jak grać na serwerze?")
	menu.AddItem("", "★ Pomoc - Klasy ★");
	menu.AddItem("", "★ Pomoc - Perki ★");
	menu.AddItem("", "★ Pomoc - Umiejętności ★");
	menu.AddItem("", "★ Pomoc - Monety ★");
	menu.AddItem("", "★ Pomoc - Klany ★");
	menu.AddItem("", "★ Pomoc - Misje ★");
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int HelpMenu_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Select: {
			switch(item) {
				case 0: {
					Menu newMenu = new Menu(SelectedHelpMenu_Handler, MENU_ACTIONS_ALL);
					newMenu.SetTitle("➫ Pomoc - Klasy")
					newMenu.AddItem("", "♦ Na serwerze jest do wybrania paredziesiąt klas");
					newMenu.AddItem("", "♦ Każda klasa posiada swoje bronie, statystyki i umiejętności.");
					newMenu.AddItem("", "♦ Wybierz najbardziej odpowiadającą Ci klasę i zdobywaj poziom");
					newMenu.AddItem("", "♦ poprzez zabijanie, cele mapy, specjalne misje i wiele innych.");
					newMenu.AddItem("", "♦ Wraz z kolejnymi poziomami rozwijaj takie statystyki klasy");
					newMenu.AddItem("", "♦ jak zdrowie, inteligencja, wytrzymałość czy kondycja, co da");
					newMenu.AddItem("", "♦ Ci przewagę nad pozostałymi graczami.");
					newMenu.AddItem("", "♦ Nie czekaj, wpisz !klasa by wybrać swoją klasę :)");
					newMenu.ExitBackButton = true;
					newMenu.Display(client, MENU_TIME_FOREVER);
				}

				case 1: {
					Menu newMenu = new Menu(SelectedHelpMenu_Handler, MENU_ACTIONS_ALL);
					newMenu.SetTitle("➫ Pomoc - Perki")
					newMenu.AddItem("", "♦ Za zabicie przeciwnika otrzymujesz losowy perk. Perki te dają");
					newMenu.AddItem("", "♦ Ci specjalne umiejętności czy bonusy. Na serwerze jest dostępnych");
					newMenu.AddItem("", "♦ kilkadziesiąt zróżnicowanych perków, ale korzystać możesz tylko z");
					newMenu.AddItem("", "♦ jednego. Jeżeli dany perk Ci nieodpowiada, możesz go wyrzucić ");
					newMenu.AddItem("", "♦ poprzez komendę !drop bądź !d, by potem upolować coś lepszego.");
					newMenu.ExitBackButton = true;
					newMenu.Display(client, MENU_TIME_FOREVER);
				}

				case 2: {
					Menu newMenu = new Menu(SelectedHelpMenu_Handler, MENU_ACTIONS_ALL);
					newMenu.SetTitle("➫ Pomoc - Umiejętności")
					newMenu.AddItem("", "♦ Niektóre klasy czy perki dają Ci umiejętności które aktywują się");
					newMenu.AddItem("", "♦ dopiero po użyciu, są to np. rakiety, miny, teleport itd. ");
					newMenu.AddItem("", "♦ Do użycia umiejętności służą:");
					newMenu.AddItem("", "★ klawisz E - dla umiejętności klasy");
					newMenu.AddItem("", "★ klawisz G - dla umiejętności perku");
					newMenu.AddItem("", "♦ Jeżeli chcesz, możesz zmienić te klawisze - więcej pod !bindy");
					newMenu.ExitBackButton = true;
					newMenu.Display(client, MENU_TIME_FOREVER);
				}

				case 3: {
					Menu newMenu = new Menu(SelectedHelpMenu_Handler, MENU_ACTIONS_ALL);
					newMenu.SetTitle("➫ Pomoc - Monety")
					newMenu.AddItem("", "♦ Oprócz doświadczenia za wykonywanie celów rozgrywki zgarniasz");
					newMenu.AddItem("", "♦ także specjalne monety. Monety możesz wykorzystać w m.in.:");
					newMenu.AddItem("", "★ Specjalnym sklepie - sprawdź !sklep");
					newMenu.AddItem("", "★ Założenie bądź rozwój klanu - sprawdź !klan");
					newMenu.AddItem("", "★ Rynku z perkami - sprawdź !rynek");
					newMenu.ExitBackButton = true;
					newMenu.Display(client, MENU_TIME_FOREVER);
				}

				case 4: {
					Menu newMenu = new Menu(SelectedHelpMenu_Handler, MENU_ACTIONS_ALL);
					newMenu.SetTitle("➫ Pomoc - Klany")
					newMenu.AddItem("", "♦ Załóż klan ze swoimi znajomymi aby zwiększyć swoje ");
					newMenu.AddItem("", "♦ umiejętności! W klanie razem ze swoimi członkami");
					newMenu.AddItem("", "♦ zbieracie monety, które potem możesz zamienić ");
					newMenu.AddItem("", "♦ na takie statystyki jak witalność, obrażenia ");
					newMenu.AddItem("", "♦ i wiele innych! Przekonaj się sam i");
					newMenu.AddItem("", "♦ czym prędzej dołącz do klanu!");
					newMenu.ExitBackButton = true;
					newMenu.Display(client, MENU_TIME_FOREVER);
				}

				case 5: {
					Menu newMenu = new Menu(SelectedHelpMenu_Handler, MENU_ACTIONS_ALL);
					newMenu.SetTitle("➫ Pomoc - Misje")
					newMenu.AddItem("", "♦ W celu zdobycia większej ilości doświadczenia ");
					newMenu.AddItem("", "♦ czy też monet, możesz wykonywać także specjalne");
					newMenu.AddItem("", "♦ misje, których nagrody są niemałe, choć same misje");
					newMenu.AddItem("", "♦ też nie zawsze do łatwych nie należą.");
					newMenu.ExitBackButton = true;
					newMenu.Display(client, MENU_TIME_FOREVER);
				}
			}
		}

		case MenuAction_End: {
			delete menu;
		}
	}
}


public int SelectedHelpMenu_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Cancel: {
			if (item == MenuCancel_ExitBack) {
				cmd_Help(client, 0);
			}
		}

		case MenuAction_DrawItem: {
			return ITEMDRAW_DISABLED;
		}

		case MenuAction_End: {
			delete menu;
		}
	}

	return 0;
}
