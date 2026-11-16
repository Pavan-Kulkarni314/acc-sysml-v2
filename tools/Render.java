import org.omg.sysml.interactive.SysMLInteractive;
import org.omg.sysml.interactive.SysMLInteractiveResult;
import org.omg.sysml.interactive.VizResult;
import net.sourceforge.plantuml.FileFormat;
import net.sourceforge.plantuml.FileFormatOption;
import net.sourceforge.plantuml.SourceStringReader;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.*;
import java.util.regex.*;

/**
 * Renders diagrams of the ACC model with the SysML v2 pilot implementation.
 *
 * Usage: Render <libraryDir> <modelDir> <outDir> <spec>...
 *   spec = QualifiedName|VIEW|fileName[|noattributes]
 *   VIEW = TREE, INTERCONNECTION, STATE, ACTION, MIXED or DEFAULT
 *   "noattributes" removes attribute boxes so ports and interfaces are easier to read.
 */
public class Render {

    private static final Pattern ATTRIBUTE_BOX = Pattern.compile(
        "comp usage \"[^\"]*\" as E\\d+\\s+<<[^\\n]*attribute>> \\[\\[[^\\]]*\\]\\] \\{\\n(?:[^}]*\\n)?\\}\\n");

    public static void main(String[] args) throws Exception {
        SysMLInteractive s = SysMLInteractive.getInstance();
        s.loadLibrary(args[0]);
        try (var files = Files.list(Path.of(args[1]))) {
            for (Path p : files.filter(f -> f.toString().endsWith(".sysml")).sorted().toList()) {
                SysMLInteractiveResult r = s.process(Files.readString(p));
                if (r.hasErrors()) {
                    System.out.println("Model has errors in " + p + ":\n" + r.formatIssues());
                    System.exit(1);
                }
            }
        }
        Path out = Path.of(args[2]);
        Files.createDirectories(out);

        for (int i = 3; i < args.length; i++) {
            String[] spec = args[i].split("\\|");
            boolean noAttributes = spec.length > 3 && spec[3].equalsIgnoreCase("noattributes");
            VizResult v = s.viz(new ArrayList<>(List.of(spec[0])), new ArrayList<>(List.of(spec[1])),
                                new ArrayList<>(List.of("STDCOLOR")), new ArrayList<>());
            String svg = v.getSVG();
            if (v.hasException() || svg == null) {
                System.out.println("Could not render " + args[i] + ": " + v);
                continue;
            }
            if (noAttributes) svg = withoutAttributes(svg);
            Files.writeString(out.resolve(spec[2] + ".svg"), svg);
            System.out.println("Wrote " + out.resolve(spec[2] + ".svg"));
        }
    }

    /** Re-renders a diagram from its embedded PlantUML source without the attribute boxes. */
    private static String withoutAttributes(String svg) throws Exception {
        String text = svg.replace("&lt;", "<").replace("&gt;", ">").replace("&quot;", "\"").replace("&amp;", "&");
        Matcher m = Pattern.compile("@startuml.*?@enduml", Pattern.DOTALL).matcher(text);
        if (!m.find()) return svg;
        String puml = ATTRIBUTE_BOX.matcher(m.group().replace("\r\n", "\n")).replaceAll("")
            .replace("skinparam ranksep 10", "skinparam ranksep 90\nskinparam nodesep 120");
        ByteArrayOutputStream os = new ByteArrayOutputStream();
        new SourceStringReader(puml).outputImage(os, new FileFormatOption(FileFormat.SVG));
        return os.toString(StandardCharsets.UTF_8);
    }
}
