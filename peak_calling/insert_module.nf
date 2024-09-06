process Hydra_insert {

        input:
        val y
        val hydra_path

        output:
        stdout

        script:
        """
        #!/bin/bash
        result="\$(echo $y | tr '[],' ' ')"
        result="\${result%% }"
        result="\${result## }"
        result=(\$result)
        for word in "\${result[@]}"; do
                t="\$(basename \$word)"
                echo "\$word"
                ndn-hydra-client insert -r /hydra -f "$hydra_path/\${t}\$RANDOM" -p "\$word" -w 4
                sleep 7
        done
        """
}