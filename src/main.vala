using Gtk;

public class BallisticPendulumApp : Gtk.Application {
    public BallisticPendulumApp() {
        Object(
            application_id: "org.example.ballisticpendulum",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate() {
        var window = new BallisticPendulumWindow(this);
        window.present();
    }

    public static int main(string[] args) {
        return new BallisticPendulumApp().run(args);
    }
}
