import org.omg.sysml.interactive.SysMLInteractive;
import org.omg.sysml.interactive.SysMLInteractiveResult;
import java.nio.file.*;

/** Loads the SysML v2 standard library, then parses and validates each file given, in order. */
public class Validate {
    public static void main(String[] args) throws Exception {
        SysMLInteractive s = SysMLInteractive.getInstance();
        s.loadLibrary(args[0]);
        int errors = 0;
        for (int i = 1; i < args.length; i++) {
            String text = Files.readString(Path.of(args[i]));
            SysMLInteractiveResult r = s.process(text);
            System.out.println("=== " + args[i] + (r.hasErrors() ? "  [ERRORS]" : "  [OK]"));
            String issues = r.formatIssues();
            if (issues != null && !issues.isBlank()) System.out.println(issues);
            if (r.getException() != null) System.out.println(r.formatException());
            if (r.hasErrors()) errors++;
        }
        System.out.println("FILES WITH ERRORS: " + errors);
        System.exit(errors == 0 ? 0 : 1);
    }
}
