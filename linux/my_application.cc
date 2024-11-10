#include "my_application.h"

#include <cfloat>
#include <cstdlib>
#include <flutter_linux/flutter_linux.h>
#include <glib.h>
#include <netinet/in.h>
#include <unistd.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

#include <arpa/inet.h>

typedef struct {
	char* ipv4;
	_MyApplication* self;
} Parg;

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* incoming_channel;
  //FlMethodChannel* outgoing_channel;
  FlView* view;

};

//static FlMethodResponse* native_ping (char *ipv4_addr) {
static void* native_ping (gpointer pargp) {
	//char ipv4_addr[16];
	Parg* parg = (Parg*)pargp;
	char* ipv4_addr = parg->ipv4;
	_MyApplication* self = parg->self;

	char chbuf[256] = {0};
	sprintf(chbuf, "warp.discover/%s\n", ipv4_addr);

	FlMethodChannel* outgoing_channel = fl_method_channel_new(
			fl_engine_get_binary_messenger(
				fl_view_get_engine(self->view)
			), 
			chbuf,
			FL_METHOD_CODEC(fl_standard_method_codec_new())
	);


	uint8_t ipv4_byte[4];
	if(EOF != sscanf(ipv4_addr, "%hhu.%hhu.%hhu.%hhu", 
				&ipv4_byte[0], 
				&ipv4_byte[1], 
				&ipv4_byte[2], 
				&ipv4_byte[3])){

		//FlValue* list = fl_value_new_list();

		//default /24
		int ipv4_hostaddr = ipv4_byte[3];
		ipv4_byte[3] = 0;
		
		for(int i = 0; i < 255; i++){
			if (i == ipv4_hostaddr) continue;
			char ipv4_target_addr[16];
			ipv4_byte[3] = i;
			sprintf(ipv4_target_addr, "%hhu.%hhu.%hhu.%hhu", 
					ipv4_byte[0], 
					ipv4_byte[1], 
					ipv4_byte[2], 
					ipv4_byte[3]);
			printf("pinging %s\n", ipv4_target_addr);
			char cmdbuf[64];
			sprintf(cmdbuf, "ping -W 0.01 -c 1 %s", ipv4_target_addr);
			if (system(cmdbuf)) {
				printf("%s found\n", ipv4_target_addr);
				//FlValue* pair = fl_value_new_list();
				//fl_value_append_take(pair, fl_value_new_string(ipv4_target_addr));
				//fl_value_append_take(list, fl_value_new_string(ipv4_target_addr));
				printf("calling %s\n", chbuf);
				fl_method_channel_invoke_method(
					outgoing_channel,
					ipv4_addr, 
					fl_value_new_string(ipv4_target_addr), 
					NULL,
					NULL,
					NULL
				);

			} else {
				printf("%s not\n", ipv4_target_addr);
			}
		}

		//return FL_METHOD_RESPONSE(fl_method_success_response_new(list));
		printf("Done\n");
		//fl_method_call_respond_success(NULL, fl_value_new_string("A"), NULL);
		
	} else {
		//return FL_METHOD_RESPONSE(
		//fl_method_error_response_new("INVALID_IP", "Invalid IPv4 address", nullptr));
		//fl_method_call_respond_error(mcall, "INVALID_IP", "Invalid IPv4 address", NULL, NULL);
	}
	//return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_string("Ping Finished!")));
	//fl_method_call_respond_success(mcall, fl_value_new_string("Ping Finished!"), NULL);
	printf("Thread Done\n");
	g_free(parg->ipv4);
	g_free(parg);
	return NULL;
}

static void startScan_method_handler(
		FlMethodChannel* channel, 
		FlMethodCall* method_call, 
		gpointer user_data) {

	_MyApplication* self = MY_APPLICATION(user_data);
	//FlValue* args = fl_method_call_get_args(method_call);
	FlValue* args = fl_method_call_get_args(method_call);
	const char* ipv4_addr = 
		fl_value_get_string(fl_value_lookup_string(args, "ipv4"));

	Parg* parg = g_new(Parg, 1);
	char* ipv4 = g_strdup(ipv4_addr);
	parg->self = self;
	parg->ipv4 = ipv4;


	g_thread_new("ping", native_ping, (gpointer)parg);
	fl_method_call_respond_success(method_call, fl_value_new_string("Ping Started!"), NULL);
	//GThread* t = g_thread_new("ping", native_ping, method_call);
	//g_thread_join(t);
}



G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
	if (use_header_bar) {
	  GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
	  gtk_widget_show(GTK_WIDGET(header_bar));
	  gtk_header_bar_set_title(header_bar, "arpa");
	  gtk_header_bar_set_show_close_button(header_bar, TRUE);
	  gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
	} else {
	  gtk_window_set_title(window, "arpa");
	}
	
	gtk_window_set_default_size(window, 1280, 720);
	gtk_widget_show(GTK_WIDGET(window));
	
	g_autoptr(FlDartProject) project = fl_dart_project_new();
	fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);
	
	FlView* view = fl_view_new(project);
	self->view = view;
	gtk_widget_show(GTK_WIDGET(view));
	gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));
	
	fl_register_plugins(FL_PLUGIN_REGISTRY(view));
	
	g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();

	self->incoming_channel = fl_method_channel_new(
			fl_engine_get_binary_messenger(fl_view_get_engine(view)), 
			"warp.native",
			FL_METHOD_CODEC(codec)
	);

	//self->outgoing_channel = fl_method_channel_new(
	//		fl_engine_get_binary_messenger(fl_view_get_engine(view)), 
	//		"warp.discover",
	//		FL_METHOD_CODEC(codec)
	//);

	
	fl_method_channel_set_method_call_handler(
			self->incoming_channel, 
			startScan_method_handler,
			self, 
			nullptr
	);
	
	gtk_widget_grab_focus(GTK_WIDGET(view));
	
	//fl_register_plugins(FL_PLUGIN_REGISTRY(self->view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_object(&self->incoming_channel);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}


