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
    private int data_count = 0; // Track total number of points added
    
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
        // Add the new data point
        angles.add(angle * 180 / Math.PI); // Convert to degrees
        times.add(time);
        data_count++;
        
        // Update max values
        if (Math.fabs(angle * 180 / Math.PI) > max_angle) {
            max_angle = Math.fabs(angle * 180 / Math.PI) + 5; // Add margin
        }
        
        if (time > max_time) {
            max_time = time + 0.5; // Add more margin for longer simulations
        }
        
        // Print the current count of data points (helpful for debugging)
        print("Data points: %d\n", data_count);
        
        queue_draw();
    }
    
    public void clear_data() {
        angles.clear();
        times.clear();
        max_angle = 0.1;
        max_time = 0.1;
        data_count = 0;
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
        
        // Draw data points and line - optimize for large datasets
        if (angles.size > 1) {
            // Draw the graph line
            cr.set_source_rgb(0.2, 0.4, 0.8);
            cr.set_line_width(2);
            
            bool first = true;
            
            // For very large datasets, draw at most one point per pixel to optimize performance
            int total_points = angles.size;
            int step = total_points > graph_width ? total_points / graph_width : 1;
            
            // Always ensure we include the first and last point
            for (int i = 0; i < angles.size; i += step) {
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
            
            // Make sure to include the last point if we're using a step > 1
            if (step > 1 && total_points > 0) {
                int last_idx = total_points - 1;
                double last_angle = angles[last_idx] ?? 0.0;
                double last_time = times[last_idx] ?? 0.0;
                
                double x = graph_x + (last_time / max_time) * graph_width;
                double y = graph_y + graph_height / 2 - (last_angle / max_angle) * (graph_height / 2);
                
                cr.line_to(x, y);
            }
            
            cr.stroke();
            
            // Draw points with optimization for large datasets
            if (total_points <= 1000) {
                // For smaller datasets, draw each point
                for (int i = 0; i < angles.size; i++) {
                    double angle_value = angles[i] ?? 0.0;
                    double time_value = times[i] ?? 0.0;
                    
                    double x = graph_x + (time_value / max_time) * graph_width;
                    double y = graph_y + graph_height / 2 - (angle_value / max_angle) * (graph_height / 2);
                    
                    cr.set_source_rgb(0.0, 0.0, 0.8);
                    cr.arc(x, y, POINT_RADIUS, 0, 2 * Math.PI);
                    cr.fill();
                }
            } else {
                // For larger datasets, draw fewer points for performance
                for (int i = 0; i < angles.size; i += step * 5) {
                    double angle_value = angles[i] ?? 0.0;
                    double time_value = times[i] ?? 0.0;
                    
                    double x = graph_x + (time_value / max_time) * graph_width;
                    double y = graph_y + graph_height / 2 - (angle_value / max_angle) * (graph_height / 2);
                    
                    cr.set_source_rgb(0.0, 0.0, 0.8);
                    cr.arc(x, y, POINT_RADIUS, 0, 2 * Math.PI);
                    cr.fill();
                }
                
                // Always draw the last point
                if (total_points > 0) {
                    int last_idx = total_points - 1;
                    double last_angle = angles[last_idx] ?? 0.0;
                    double last_time = times[last_idx] ?? 0.0;
                    
                    double x = graph_x + (last_time / max_time) * graph_width;
                    double y = graph_y + graph_height / 2 - (last_angle / max_angle) * (graph_height / 2);
                    
                    cr.set_source_rgb(0.0, 0.0, 0.8);
                    cr.arc(x, y, POINT_RADIUS, 0, 2 * Math.PI);
                    cr.fill();
                }
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
                
                // Prepare hover texts
                string time_text = "Время: %.2f с".printf(time_value);
                string angle_text = "Угол: %.2f°".printf(angle_value);
                
                // Get text dimensions for both text items
                cr.set_font_size(12);
                Cairo.TextExtents time_extents;
                Cairo.TextExtents angle_extents;
                cr.text_extents(time_text, out time_extents);
                cr.text_extents(angle_text, out angle_extents);
                
                // Calculate the maximum width needed
                double max_width = double.max(time_extents.width, angle_extents.width);
                
                // Position the hover info
                double text_x = x + 10;
                double text_y = y - 10;
                double box_height = time_extents.height + angle_extents.height + 10; // Add padding
                
                // Adjust position if too close to edge
                if (text_x + max_width + 15 > width) {
                    text_x = x - max_width - 15;
                }
                
                if (text_y - box_height < 0) {
                    text_y = y + 25;
                }
                
                // Draw unified text background with proper dimensions
                cr.set_source_rgba(1.0, 1.0, 1.0, 0.85);
                cr.rectangle(text_x - 5, 
                             text_y - box_height,
                             max_width + 10, 
                             box_height + 5);
                cr.fill();
                
                // Draw border around text
                cr.set_source_rgba(0.5, 0.5, 0.5, 0.8);
                cr.rectangle(text_x - 5, 
                             text_y - box_height,
                             max_width + 10, 
                             box_height + 5);
                cr.stroke();
                
                // Draw texts
                cr.set_source_rgb(0.0, 0.0, 0.0);
                cr.move_to(text_x, text_y - angle_extents.height - 5);
                cr.show_text(time_text);
                cr.move_to(text_x, text_y);
                cr.show_text(angle_text);
            }
        }
    }
}
