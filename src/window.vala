using Gtk;

public class BallisticPendulumWindow : Gtk.ApplicationWindow {
    private SimulationArea simulation_area;
    private OscillationGraph oscillation_graph;
    private Gtk.Scale ball_mass_scale;
    private Gtk.Scale pendulum_mass_scale;
    private Gtk.Scale launch_power_scale;
    private Gtk.Scale simulation_speed_scale;
    private Gtk.Label velocity_label;
    private Gtk.Label angle_label;
    private Gtk.Button launch_button;
    private Gtk.Button reset_button;

    public BallisticPendulumWindow(Gtk.Application app) {
        Object(
            application: app,
            title: "Баллистический маятник",
            default_width: 1000,
            default_height: 700
        );

        // Use a scrolled window as main container to ensure all content is accessible
        var scrolled_window = new Gtk.ScrolledWindow();
        scrolled_window.set_min_content_width(600);
        scrolled_window.set_min_content_height(500);
        
        var main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10) {
            margin_start = 10,
            margin_end = 10,
            margin_top = 10,
            margin_bottom = 10
        };
        
        // Create paned container to split the view
        var paned = new Gtk.Paned(Gtk.Orientation.VERTICAL);
        // Set position to 60% of height for better default proportions on smaller screens
        paned.set_position(350);
        
        // Upper frame - simulation area
        var simulation_frame = new Gtk.Frame("Симуляция") {
            margin_bottom = 10,
            halign = Gtk.Align.CENTER
        };
        simulation_frame.set_label_align(0.5f);
        
        // Simulation area
        simulation_area = new SimulationArea();
        simulation_area.set_size_request(600, 300); // Smaller minimum size
        simulation_area.vexpand = true;
        simulation_area.hexpand = true;
        simulation_frame.set_child(simulation_area);
        
        // Lower panel with controls in a more flexible layout
        var lower_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
        
        // Create a box for the graph and controls side by side
        var controls_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
        controls_row.set_homogeneous(true); // Each gets equal space
        
        // Left frame - oscillation graph
        var graph_frame = new Gtk.Frame("График колебаний маятника");
        graph_frame.set_label_align(0.5f);
        
        oscillation_graph = new OscillationGraph();
        oscillation_graph.set_size_request(300, 200);
        oscillation_graph.vexpand = true;
        oscillation_graph.hexpand = true;
        graph_frame.set_child(oscillation_graph);
        
        // Right frame - control panel
        var controls_frame = new Gtk.Frame("Управление");
        controls_frame.set_label_align(0.5f);
        
        var controls_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10) {
            margin_start = 10,
            margin_end = 10,
            margin_top = 10,
            margin_bottom = 10
        };
        
        // Parameter controls in a more compact layout
        var params_grid = new Gtk.Grid() {
            row_spacing = 5,
            column_spacing = 10,
            margin_bottom = 10
        };
        
        // Row 1: Ball mass
        params_grid.attach(new Gtk.Label("Масса шарика (г):"), 0, 0, 1, 1);
        ball_mass_scale = new Gtk.Scale(Gtk.Orientation.HORIZONTAL, new Gtk.Adjustment(10, 5, 50, 1, 5, 0));
        ball_mass_scale.draw_value = true;
        ball_mass_scale.value_pos = Gtk.PositionType.RIGHT;
        ball_mass_scale.width_request = 150;
        ball_mass_scale.hexpand = true;
        params_grid.attach(ball_mass_scale, 1, 0, 1, 1);
        
        // Row 2: Pendulum mass
        params_grid.attach(new Gtk.Label("Масса маятника (г):"), 0, 1, 1, 1);
        pendulum_mass_scale = new Gtk.Scale(Gtk.Orientation.HORIZONTAL, new Gtk.Adjustment(100, 50, 500, 10, 50, 0));
        pendulum_mass_scale.draw_value = true;
        pendulum_mass_scale.value_pos = Gtk.PositionType.RIGHT;
        pendulum_mass_scale.hexpand = true;
        params_grid.attach(pendulum_mass_scale, 1, 1, 1, 1);
        
        // Row 3: Launch power
        params_grid.attach(new Gtk.Label("Сила запуска:"), 0, 2, 1, 1);
        launch_power_scale = new Gtk.Scale(Gtk.Orientation.HORIZONTAL, new Gtk.Adjustment(50, 10, 100, 1, 10, 0));
        launch_power_scale.draw_value = true;
        launch_power_scale.value_pos = Gtk.PositionType.RIGHT;
        launch_power_scale.hexpand = true;
        params_grid.attach(launch_power_scale, 1, 2, 1, 1);
        
        // Row 4: Simulation speed
        params_grid.attach(new Gtk.Label("Скорость симуляции:"), 0, 3, 1, 1);
        simulation_speed_scale = new Gtk.Scale(Gtk.Orientation.HORIZONTAL, new Gtk.Adjustment(1.0, 0.25, 5.0, 0.25, 1.0, 0));
        simulation_speed_scale.draw_value = true;
        simulation_speed_scale.value_pos = Gtk.PositionType.RIGHT;
        simulation_speed_scale.hexpand = true;
        
        // Add marks to the speed scale
        simulation_speed_scale.add_mark(0.25, Gtk.PositionType.BOTTOM, "0.25×");
        simulation_speed_scale.add_mark(1.0, Gtk.PositionType.BOTTOM, "1×");
        simulation_speed_scale.add_mark(2.0, Gtk.PositionType.BOTTOM, "2×");
        simulation_speed_scale.add_mark(5.0, Gtk.PositionType.BOTTOM, "5×");
        
        params_grid.attach(simulation_speed_scale, 1, 3, 1, 1);
        
        // Measurement display
        var measurement_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 5) {
            margin_top = 10,
            margin_bottom = 10,
            margin_start = 5,
            margin_end = 5
        };
        velocity_label = new Gtk.Label("Скорость шарика: 0 м/с");
        velocity_label.halign = Gtk.Align.START;
        angle_label = new Gtk.Label("Угол отклонения: 0°");
        angle_label.halign = Gtk.Align.START;
        
        measurement_box.append(velocity_label);
        measurement_box.append(angle_label);
        
        // Buttons
        var button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10) {
            margin_top = 10,
            margin_bottom = 5,
            halign = Gtk.Align.CENTER
        };
        
        launch_button = new Gtk.Button.with_label("Запустить");
        launch_button.clicked.connect(on_launch_clicked);
        launch_button.add_css_class("suggested-action");
        launch_button.hexpand = true;
        button_box.append(launch_button);
        
        reset_button = new Gtk.Button.with_label("Сбросить");
        reset_button.clicked.connect(on_reset_clicked);
        reset_button.sensitive = false;
        reset_button.hexpand = true;
        button_box.append(reset_button);
        
        // Add all elements to the controls box
        controls_box.append(params_grid);
        controls_box.append(measurement_box);
        controls_box.append(button_box);
        
        controls_frame.set_child(controls_box);
        
        // Add frames to the controls row
        controls_row.append(graph_frame);
        controls_row.append(controls_frame);
        
        // Add the controls row to the lower box
        lower_box.append(controls_row);
        
        // Add panels to the main paned container
        paned.set_start_child(simulation_frame);
        paned.set_end_child(lower_box);
        
        // Add everything to the main box
        main_box.append(paned);
        
        // Set up scrolled window
        scrolled_window.set_child(main_box);
        this.set_child(scrolled_window);
        
        // Connect signals to update parameters
        ball_mass_scale.value_changed.connect(() => {
            simulation_area.ball_mass = ball_mass_scale.get_value();
        });
        
        pendulum_mass_scale.value_changed.connect(() => {
            simulation_area.pendulum_mass = pendulum_mass_scale.get_value();
        });
        
        launch_power_scale.value_changed.connect(() => {
            simulation_area.launch_power = launch_power_scale.get_value();
        });
        
        simulation_speed_scale.value_changed.connect(() => {
            simulation_area.simulation_speed = simulation_speed_scale.get_value();
        });
        
        // Setup initial values
        simulation_area.ball_mass = ball_mass_scale.get_value();
        simulation_area.pendulum_mass = pendulum_mass_scale.get_value();
        simulation_area.launch_power = launch_power_scale.get_value();
        simulation_area.simulation_speed = simulation_speed_scale.get_value();
        
        // Connect signals for measurements update and pendulum angle update
        simulation_area.measurements_updated.connect(update_measurements);
        simulation_area.pendulum_moved.connect((angle, time) => {
            oscillation_graph.add_data_point(angle, time);
        });
    }
    
    private void on_launch_clicked() {
        launch_button.sensitive = false;
        reset_button.sensitive = true;
        ball_mass_scale.sensitive = false;
        pendulum_mass_scale.sensitive = false;
        launch_power_scale.sensitive = false;
        
        oscillation_graph.clear_data();
        simulation_area.launch_ball();
    }
    
    private void on_reset_clicked() {
        simulation_area.reset();
        launch_button.sensitive = true;
        reset_button.sensitive = false;
        ball_mass_scale.sensitive = true;
        pendulum_mass_scale.sensitive = true;
        launch_power_scale.sensitive = true;
        
        // Update the UI with final measurements after reset
        if (simulation_area.has_final_measurements()) {
            update_measurements(simulation_area.get_final_velocity(), simulation_area.get_final_angle());
        } else {
            velocity_label.set_text("Скорость шарика: 0 м/с");
            angle_label.set_text("Угол отклонения: 0°");
        }
    }
    
    private void update_measurements(double velocity, double angle) {
        velocity_label.set_text("Скорость шарика: %.2f м/с".printf(velocity));
        angle_label.set_text("Угол отклонения: %.2f°".printf(angle));
    }
}
