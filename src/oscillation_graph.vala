using Gtk;

public class OscillationGraph : Gtk.DrawingArea {
    // Graph data
    private Gee.ArrayList<double?> angles;
    private Gee.ArrayList<double?> times;
    private double max_angle;
    private double max_time;
    private double hover_x;
    private double hover_y;
    private bool is_hovering;
    
    // Constants
    private const int PADDING = 20;
    private const int AXIS_MARGIN = 30;
    
    // Graph visual properties
    private const double POINT_RADIUS = 2;
    
    public OscillationGraph() {
        angles = new Gee.ArrayList<double?>();
        times = new Gee.ArrayList<double?>();
        max_angle = 0.1; // Small initial value to avoid division by zero
        max_time = 0.1;  // Small initial value to avoid division by zero
        is_hovering = false;
        
        set_draw_func(draw);
        
        // Setup motion event controller for hover
        var motion_controller = new Gtk.EventControllerMotion();
        motion_controller.motion.connect((x, y) => {
            hover_x = x;
            hover_y = y;
            is_hovering = true;
            queue_draw();
        });
        
        motion_controller.leave.connect(() => {
            is_hovering = false;
            queue_draw();
        });
        
        add_controller(motion_controller);
        
        // Make the widget focusable
        set_can_focus(true);
        set_focusable(true);
    }
    
    public void add_data_point(double angle, double time) {
        angles.add(angle * 180 / Math.PI); // Convert to degrees
        times.add(time);
        
        // Update max values
        if (Math.fabs(angle * 180 / Math.PI) > max_angle) {
            max_angle = Math.fabs(angle * 180 / Math.PI) + 5; // Add margin
        }
        
        if (time > max_time) {
            max_time = time + 0.5; // Add more margin for longer simulations
        }
        
        // Limit data points to avoid performance issues with very long simulations
        if (angles.size > 1000) {
            // Keep only every other point when we get too many
            Gee.ArrayList<double?> new_angles = new Gee.ArrayList<double?>();
            Gee.ArrayList<double?> new_times = new Gee.ArrayList<double?>();
            
            for (int i = 0; i < angles.size; i += 2) {
                new_angles.add(angles[i]);
                new_times.add(times[i]);
            }
            
            angles = new_angles;
            times = new_times;
        }
        
        queue_draw();
    }
    
    public void clear_data() {
        angles.clear();
        times.clear();
        max_angle = 0.1;
        max_time = 0.1;
        queue_draw();
    }
    
    private void draw(Gtk.DrawingArea da, Cairo.Context cr, int width, int height) {
        // Draw background
        cr.set_source_rgb(1.0, 1.0, 1.0);
        cr.rectangle(0, 0, width, height);
        cr.fill();
        
        // Available drawing area
        int graph_width = width - 2 * PADDING - AXIS_MARGIN;
        int graph_height = height - 2 * PADDING - AXIS_MARGIN;
        int graph_x = PADDING + AXIS_MARGIN;
        int graph_y = PADDING;
        
        // Draw axes
        cr.set_source_rgb(0.0, 0.0, 0.0);
        cr.set_line_width(1);
        
        // X-axis (time)
        cr.move_to(graph_x, graph_y + graph_height);
        cr.line_to(graph_x + graph_width, graph_y + graph_height);
        cr.stroke();
        
        // Y-axis (angle)
        cr.move_to(graph_x, graph_y);
        cr.line_to(graph_x, graph_y + graph_height);
        cr.stroke();
        
        // Draw grid
        cr.set_source_rgba(0.7, 0.7, 0.7, 0.3);
        cr.set_dash({5.0, 5.0}, 0);
        
        // Horizontal grid lines and labels
        for (int i = -5; i <= 5; i++) {
            if (i == 0) continue; // Skip center line (X-axis)
            
            double y_pos = graph_y + graph_height / 2 - i * graph_height / (2 * 5);
            cr.move_to(graph_x, y_pos);
            cr.line_to(graph_x + graph_width, y_pos);
            
            cr.save();
            cr.set_source_rgb(0.3, 0.3, 0.3);
            cr.set_dash({}, 0); // Remove dash
            cr.move_to(graph_x - 25, y_pos + 5);
            cr.show_text("%d°".printf((int)(i * max_angle / 5)));
            cr.restore();
        }
        
        // Vertical grid lines and labels
        int time_steps = ((int)(max_time / 0.2) < 10) ? (int)(max_time / 0.2) : 10;
        for (int i = 1; i <= time_steps; i++) {
            double x_pos = graph_x + i * graph_width / time_steps;
            cr.move_to(x_pos, graph_y);
            cr.line_to(x_pos, graph_y + graph_height);
            
            cr.save();
            cr.set_source_rgb(0.3, 0.3, 0.3);
            cr.set_dash({}, 0); // Remove dash
            cr.move_to(x_pos - 10, graph_y + graph_height + 15);
            cr.show_text("%.1fs".printf(i * max_time / time_steps));
            cr.restore();
        }
        
        cr.stroke();
        cr.set_dash({}, 0); // Remove dash
        
        // Draw center line (angle = 0)
        cr.set_source_rgba(0.5, 0.5, 0.5, 0.8);
        cr.move_to(graph_x, graph_y + graph_height / 2);
        cr.line_to(graph_x + graph_width, graph_y + graph_height / 2);
        cr.stroke();
        
        // Draw axes labels
        cr.set_source_rgb(0.0, 0.0, 0.0);
        cr.move_to(graph_x + graph_width / 2, graph_y + graph_height + 30);
        cr.show_text("Время (с)");
        
        cr.save();
        cr.move_to(graph_x - 25, graph_y + graph_height / 2 - 15);
        cr.rotate(-Math.PI / 2);
        cr.show_text("Угол (°)");
        cr.restore();
        
        // Draw data points and line
        if (angles.size > 1) {
            // Draw the graph line
            cr.set_source_rgb(0.2, 0.4, 0.8);
            cr.set_line_width(2);
            
            bool first = true;
            for (int i = 0; i < angles.size; i++) {
                double angle_value = angles[i] ?? 0.0;
                double time_value = times[i] ?? 0.0;
                
                double x = graph_x + (time_value / max_time) * graph_width;
                double y = graph_y + graph_height / 2 - (angle_value / max_angle) * (graph_height / 2);
                
                if (first) {
                    cr.move_to(x, y);
                    first = false;
                } else {
                    cr.line_to(x, y);
                }
            }
            cr.stroke();
            
            // Draw points
            for (int i = 0; i < angles.size; i++) {
                double angle_value = angles[i] ?? 0.0;
                double time_value = times[i] ?? 0.0;
                
                double x = graph_x + (time_value / max_time) * graph_width;
                double y = graph_y + graph_height / 2 - (angle_value / max_angle) * (graph_height / 2);
                
                cr.set_source_rgb(0.0, 0.0, 0.8);
                cr.arc(x, y, POINT_RADIUS, 0, 2 * Math.PI);
                cr.fill();
            }
        }
        
        // Handle hover information
        if (is_hovering && angles.size > 1) {
            // Check if hover is within graph area
            if (hover_x >= graph_x && hover_x <= graph_x + graph_width &&
                hover_y >= graph_y && hover_y <= graph_y + graph_height) {
                
                // Find closest time point
                double hover_time = (hover_x - graph_x) * max_time / graph_width;
                int closest_idx = 0;
                double min_time_diff = double.MAX;
                
                for (int i = 0; i < times.size; i++) {
                    double time_value = times[i] ?? 0.0;
                    double time_diff = Math.fabs(time_value - hover_time);
                    if (time_diff < min_time_diff) {
                        min_time_diff = time_diff;
                        closest_idx = i;
                    }
                }
                
                // Calculate position
                double angle_value = angles[closest_idx] ?? 0.0;
                double time_value = times[closest_idx] ?? 0.0;
                
                double x = graph_x + (time_value / max_time) * graph_width;
                double y = graph_y + graph_height / 2 - (angle_value / max_angle) * (graph_height / 2);
                
                // Draw hover point highlight
                cr.set_source_rgb(0.9, 0.1, 0.1);
                cr.arc(x, y, POINT_RADIUS * 2, 0, 2 * Math.PI);
                cr.fill();
                
                // Draw hover info box
                string hover_text = "Время: %.2f с\nУгол: %.2f°".printf(
                    time_value, angle_value);
                
                // Background for text
                Cairo.TextExtents extents;
                cr.set_font_size(12);
                cr.text_extents(hover_text, out extents);
                
                double text_x = x + 10;
                double text_y = y - 10;
                
                // Adjust position if too close to edge
                if (text_x + extents.width + 10 > width) {
                    text_x = x - extents.width - 10;
                }
                
                if (text_y - extents.height - 10 < 0) {
                    text_y = y + extents.height + 10;
                }
                
                // Draw text background
                cr.set_source_rgba(1.0, 1.0, 1.0, 0.85);
                cr.rectangle(text_x - 5, text_y - extents.height - 5, 
                             extents.width + 10, extents.height + 10);
                cr.fill();
                
                // Draw border around text
                cr.set_source_rgba(0.5, 0.5, 0.5, 0.8);
                cr.rectangle(text_x - 5, text_y - extents.height - 5, 
                             extents.width + 10, extents.height + 10);
                cr.stroke();
                
                // Draw text
                cr.set_source_rgb(0.0, 0.0, 0.0);
                cr.move_to(text_x, text_y);
                cr.show_text("Время: %.2f с".printf(time_value));
                cr.move_to(text_x, text_y + extents.height + 2);
                cr.show_text("Угол: %.2f°".printf(angle_value));
            }
        }
    }
}
