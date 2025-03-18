using Gtk;

public class SimulationArea : Gtk.DrawingArea {
    // Physics properties
    public double ball_mass { get; set; default = 10; }
    public double pendulum_mass { get; set; default = 100; }
    public double launch_power { get; set; default = 50; }
    public double simulation_speed { get; set; default = 1.0; }
    
    // Simulation state
    private double ball_x;
    private double ball_y;
    private double ball_velocity_x;
    private double ball_velocity_y;
    private double pendulum_angle;
    private double pendulum_angular_velocity;
    private double max_pendulum_angle;
    private bool ball_launched;
    private bool ball_hit_pendulum;
    private uint animation_source_id;
    private double simulation_time;
    private bool measurements_reported;
    private double final_velocity;
    private double final_angle_degrees;
    
    // Oscillation dampening detection
    private int stable_frames_count;
    private const int REQUIRED_STABLE_FRAMES = 60; // 1 second at 60fps
    private const double STABILITY_THRESHOLD = 0.0001;
    
    // Constants
    private const double GRAVITY = 9.81;
    private const double SPOKE_LENGTH = 180;
    private const double PIVOT_X = 400;
    private const double PIVOT_Y = 150;
    private const double BALL_RADIUS = 10;
    private const double CYLINDER_RADIUS = 40;
    private const double CYLINDER_HEIGHT = 80;
    private const double LAUNCHER_X = 150;
    private const double LAUNCHER_Y = 250;
    private const double TIME_STEP = 1.0 / 60.0; // 60 fps
    
    // Signals
    public signal void measurements_updated(double velocity, double angle);
    public signal void pendulum_moved(double angle, double time);
    
    public SimulationArea() {
        set_draw_func(draw);
        reset();
    }
    
    public void reset() {
        ball_x = LAUNCHER_X;
        ball_y = LAUNCHER_Y;
        ball_velocity_x = 0;
        ball_velocity_y = 0;
        pendulum_angle = 0;
        pendulum_angular_velocity = 0;
        max_pendulum_angle = 0;
        ball_launched = false;
        ball_hit_pendulum = false;
        simulation_time = 0;
        stable_frames_count = 0;
        measurements_reported = false;
        
        if (animation_source_id > 0) {
            Source.remove(animation_source_id);
            animation_source_id = 0;
        }
        
        queue_draw();
    }
    
    public bool has_final_measurements() {
        return measurements_reported;
    }
    
    public double get_final_velocity() {
        return final_velocity;
    }
    
    public double get_final_angle() {
        return final_angle_degrees;
    }
    
    public void launch_ball() {
        if (!ball_launched) {
            ball_launched = true;
            double power_factor = launch_power / 50.0; // Normalize to 0-2 range
            ball_velocity_x = 300 * power_factor; // Initial velocity
            
            animation_source_id = Timeout.add(1000 / 60, update_simulation);
        }
    }
    
    private bool update_simulation() {
        // Calculate actual time step based on simulation speed
        double actual_time_step = TIME_STEP * simulation_speed;
        
        if (!ball_hit_pendulum) {
            // Update ball position
            ball_x += ball_velocity_x * actual_time_step;
            ball_y += ball_velocity_y * actual_time_step;
            
            // Apply gravity
            ball_velocity_y += GRAVITY * 100 * actual_time_step;
            
            // Calculate pendulum cylinder position based on the angle
            double cylinder_x = PIVOT_X + SPOKE_LENGTH * Math.sin(pendulum_angle);
            double cylinder_y = PIVOT_Y + SPOKE_LENGTH * Math.cos(pendulum_angle);
            
            // Check for collision with cylinder along its axis
            double dx = ball_x - cylinder_x;
            double dy = ball_y - cylinder_y;
            double distance = Math.sqrt(dx*dx + dy*dy);
            
            if (distance < CYLINDER_RADIUS + BALL_RADIUS) {
                // Check if ball is approaching from the front
                double dot_product = dx * (-Math.sin(pendulum_angle)) + dy * (-Math.cos(pendulum_angle));
                
                if (dot_product > 0) {
                    ball_hit_pendulum = true;
                    
                    // Calculate impulse and resulting angular velocity using conservation of momentum
                    double ball_momentum = ball_mass * ball_velocity_x;
                    double combined_mass = ball_mass + pendulum_mass;
                    
                    // Calculate velocity after collision (inelastic collision)
                    double combined_velocity = ball_momentum / combined_mass;
                    
                    // Convert to angular velocity - use perpendicular distance from pivot to ball trajectory
                    double perpendicular_dist = SPOKE_LENGTH;
                    pendulum_angular_velocity = combined_velocity / perpendicular_dist;
                }
            }
        } else {
            // Update simulation time
            simulation_time += actual_time_step;
            
            // Update pendulum angle
            pendulum_angle += pendulum_angular_velocity * actual_time_step;
            
            // Apply gravity torque - considering the center of mass of pendulum+ball
            double cm_radius = SPOKE_LENGTH; // Approximate center of mass distance
            double gravity_torque = GRAVITY * (ball_mass + pendulum_mass) * Math.sin(pendulum_angle) * cm_radius * actual_time_step;
            pendulum_angular_velocity -= gravity_torque / (10 * (ball_mass + pendulum_mass) * cm_radius * cm_radius);
            
            // Apply damping - slightly less damping for longer oscillations
            pendulum_angular_velocity *= 0.9995;
            
            // Track maximum angle for measurement
            if (Math.fabs(pendulum_angle) > Math.fabs(max_pendulum_angle)) {
                max_pendulum_angle = pendulum_angle;
            }
            
            // Send angle data to graph
            pendulum_moved(pendulum_angle, simulation_time);
            
            // Check if oscillations have dampened enough
            if (Math.fabs(pendulum_angular_velocity) < STABILITY_THRESHOLD) {
                stable_frames_count++;
                
                // Report measurements once when pendulum has almost stopped
                if (!measurements_reported && stable_frames_count > 10) {
                    // Calculate ball velocity from maximum angle
                    double height = SPOKE_LENGTH * (1 - Math.cos(max_pendulum_angle));
                    final_velocity = Math.sqrt(2 * GRAVITY * height * 
                        ((ball_mass + pendulum_mass) / ball_mass));
                    
                    // Convert radians to degrees for display
                    final_angle_degrees = max_pendulum_angle * 180 / Math.PI;
                    
                    measurements_updated(final_velocity, final_angle_degrees);
                    measurements_reported = true;
                }
                
                // Stop the simulation when pendulum has been stable for long enough
                if (stable_frames_count >= REQUIRED_STABLE_FRAMES) {
                    return false; // Stop animation
                }
            } else {
                // Reset stability counter if pendulum is still moving significantly
                stable_frames_count = 0;
            }
        }
        
        queue_draw();
        return true;
    }
    
    private void draw(Gtk.DrawingArea da, Cairo.Context cr, int width, int height) {
        // Get the center of the drawing area for better positioning
        double center_x = width / 2.0;
        // Remove unused variable center_y since we're not using vertical centering
        
        // Calculate offsets to center the simulation
        double x_offset = center_x - PIVOT_X;
        double y_offset = 0; // Keep vertical position the same
        
        // Clear the background
        cr.set_source_rgb(0.95, 0.95, 0.95);
        cr.paint();
        
        // Save the context to restore later
        cr.save();
        
        // Translate to center the simulation
        cr.translate(x_offset, y_offset);
        
        // Draw the vertical stand
        cr.set_source_rgb(0.4, 0.4, 0.4);
        cr.rectangle(PIVOT_X - 10, 0, 20, PIVOT_Y + 10);
        cr.fill();
        
        // Draw the angle sensor housing
        cr.set_source_rgb(0.3, 0.3, 0.3);
        cr.rectangle(PIVOT_X - 25, PIVOT_Y - 25, 50, 50);
        cr.fill();
        
        // Draw the angle sensor display
        cr.set_source_rgb(0.0, 0.0, 0.0);
        cr.arc(PIVOT_X, PIVOT_Y, 20, 0, 2 * Math.PI);
        cr.stroke();
        
        cr.set_source_rgb(0.8, 0.0, 0.0);
        cr.move_to(PIVOT_X, PIVOT_Y);
        cr.line_to(PIVOT_X + 15 * Math.cos(pendulum_angle - Math.PI/2),
                  PIVOT_Y + 15 * Math.sin(pendulum_angle - Math.PI/2));
        cr.stroke();
        
        // Draw the launcher
        cr.set_source_rgb(0.5, 0.3, 0.0);
        cr.rectangle(LAUNCHER_X - 90, LAUNCHER_Y - 15, 90, 30);
        cr.fill();
        
        // Spring mechanism
        cr.set_source_rgb(0.7, 0.7, 0.7);
        for (int i = 0; i < 8; i++) {
            double x = LAUNCHER_X - 80 + i * 10;
            cr.move_to(x, LAUNCHER_Y - 5);
            cr.line_to(x + 5, LAUNCHER_Y + 5);
        }
        cr.stroke();
        
        // Draw a ruler
        cr.set_source_rgb(0.8, 0.8, 0.0);
        cr.rectangle(PIVOT_X - 200, height - 30, 400, 10);
        cr.fill();
        
        // Draw marks on the ruler
        cr.set_source_rgb(0.0, 0.0, 0.0);
        for (int i = -10; i <= 10; i++) {
            double x = PIVOT_X + i * 20;
            double y = height - 30;
            double mark_height = (i % 5 == 0) ? 15 : 5;
            cr.move_to(x, y);
            cr.line_to(x, y + mark_height);
            if (i % 5 == 0) {
                cr.move_to(x - 5, y + 25);
                cr.show_text("%d".printf(i * 10));
            }
        }
        cr.stroke();
        
        // Calculate pendulum position
        double cylinder_x = PIVOT_X + SPOKE_LENGTH * Math.sin(pendulum_angle);
        double cylinder_y = PIVOT_Y + SPOKE_LENGTH * Math.cos(pendulum_angle);
        
        // Draw the pendulum
        cr.save();
        
        // Draw the spoke
        cr.set_source_rgb(0.6, 0.6, 0.6);
        cr.set_line_width(3);
        cr.move_to(PIVOT_X, PIVOT_Y);
        cr.line_to(cylinder_x, cylinder_y);
        cr.stroke();
        
        // Draw the cylinder
        cr.save();
        cr.translate(cylinder_x, cylinder_y);
        cr.rotate(pendulum_angle);
        
        // Cylinder body
        cr.set_source_rgb(0.7, 0.2, 0.2);
        // Draw cylinder front circle
        cr.arc(0, 0, CYLINDER_RADIUS, 0, 2 * Math.PI);
        cr.fill();
        
        // Indicate front of cylinder with cross pattern
        cr.set_source_rgb(0.5, 0.5, 0.5);
        cr.set_line_width(1);
        cr.move_to(-CYLINDER_RADIUS + 5, -CYLINDER_RADIUS + 5);
        cr.line_to(CYLINDER_RADIUS - 5, CYLINDER_RADIUS - 5);
        cr.move_to(CYLINDER_RADIUS - 5, -CYLINDER_RADIUS + 5);
        cr.line_to(-CYLINDER_RADIUS + 5, CYLINDER_RADIUS - 5);
        cr.stroke();
        
        // Draw the conical insert
        cr.set_source_rgb(0.8, 0.8, 0.8);
        cr.move_to(-CYLINDER_RADIUS/2, -CYLINDER_RADIUS/2);
        cr.line_to(0, 0);
        cr.line_to(-CYLINDER_RADIUS/2, CYLINDER_RADIUS/2);
        cr.close_path();
        cr.fill();
        
        if (ball_hit_pendulum) {
            // Draw the ball embedded in the cylinder
            cr.set_source_rgb(0.1, 0.1, 0.8);
            cr.arc(0, 0, BALL_RADIUS, 0, 2 * Math.PI);
            cr.fill();
        }
        
        cr.restore(); // Restore after cylinder rotation
        cr.restore(); // Restore after pendulum drawing
        
        // Draw the ball if not hit the pendulum yet
        if (ball_launched && !ball_hit_pendulum) {
            cr.set_source_rgb(0.1, 0.1, 0.8);
            cr.arc(ball_x, ball_y, BALL_RADIUS, 0, 2 * Math.PI);
            cr.fill();
            
            // Draw motion trail
            cr.set_source_rgba(0.1, 0.1, 0.8, 0.3);
            for (int i = 1; i <= 5; i++) {
                double trail_x = ball_x - i * ball_velocity_x * TIME_STEP * 3;
                double trail_y = ball_y - i * ball_velocity_y * TIME_STEP * 3;
                cr.arc(trail_x, trail_y, BALL_RADIUS * (1.0 - i * 0.15), 0, 2 * Math.PI);
                cr.fill();
            }
        } else if (!ball_launched) {
            // Draw ball at starting position
            cr.set_source_rgb(0.1, 0.1, 0.8);
            cr.arc(ball_x, ball_y, BALL_RADIUS, 0, 2 * Math.PI);
            cr.fill();
        }
        
        // Restore the context after drawing all simulation elements
        cr.restore();
    }
}
