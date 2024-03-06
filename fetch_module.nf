process Hydra_fetch {

        input:
        val x
        val output_path

        output:
        //val("fetch_complete"), emit: input_done
        //val input_done
        path "temp.txt"


        script:
        """
        #!/bin/python3
        import subprocess
        import time
        import os

        process = subprocess.run("ndn-hydra-client query -r /hydra -q /files", text=True, shell=True, check=True, capture_output=True)
        process=process.stdout
        paths=[]
        for path in process.split():
                if path.startswith("$x/"):
                        paths.append(path)
        for files in paths:
                filename=os.path.basename(files)
                command="ndn-hydra-client fetch -r /hydra -f {} -p $output_path/{}".format(files,filename)
                p=subprocess.run(command,shell=True, check=True, stdout=subprocess.PIPE, universal_newlines=True)
                time.sleep(5)
                print(p)
        time.sleep(2)
        process = subprocess.run("touch temp.txt", text=True, shell=True, check=True, capture_output=True)

        """
}