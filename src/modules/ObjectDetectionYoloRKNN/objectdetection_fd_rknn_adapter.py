# Import our general libraries
import os
import sys
from time import time

# Import the CodeProject.AI SDK. This will add to the PATH var for future imports
sys.path.append("../../SDK/Python")
from common import JSON
from request_data import RequestData
from module_runner import ModuleRunner
from module_logging import LogMethod

# Import the method of the module we're wrapping
from options import Options
from PIL import Image

# Import the method of the module we're wrapping
from objectdetection_fd_rknn import init_detect, do_detect


class FastDeploy_adapter(ModuleRunner):
   
    def __init__(self):
        super().__init__()
        self.opts = Options()
        self.models_last_checked = None
        self.model_names         = []  # We'll use this to cache the available model names


    def initialise(self) -> None:
        # if the module was launched outside of the server then the queue name 
        # wasn't set. This is normally fine, but here we want the queue to be
        # the same as the other object detection queues
        
        if not self.launched_by_server:
            self.queue_name = "objectdetection_queue"

        if self.support_GPU:
            self.support_GPU = self.hasFastDeployRockNPU

        if self.support_GPU:
            print("Rockchip NPU detected")
            self.execution_provider = "RKNPU"

        init_detect(self.opts)
        

    def process(self, data: RequestData) -> JSON:

        response = None
        
        # The route to here is /v1/vision/custom/list  list all models available
        if data.command == "list-custom":
            response = self.list_models(self.opts.custom_models_dir)

        elif data.command == "detect":                  # Perform 'standard' object detection

            # The route to here is /v1/vision/detection
            threshold: float = float(data.get_value("min_confidence", self.opts.min_confidence))
            img: Image       = data.get_image(0)

            response = do_detect(self, self.opts.models_dir, self.opts.std_model_name, img, threshold)
            
        elif data.command == "custom":                  # Perform custom object detection

            threshold: float  = float(data.get_value("min_confidence", self.opts.min_confidence))
            img: Image        = data.get_image(0)

            # The route to here is /v1/vision/custom/<model-name>. if mode-name = general,
            # or no model provided, then a built-in general purpose mode will be used.
            models_dir:str  = self.opts.custom_models_dir
            model_name:str = "general"
            if data.segments and data.segments[0]:
                model_name = data.segments[0]

            # Map the "general" model to our current "general" model
            if model_name == "general":                # Use the custom IP Cam general model
                models_dir  = self.opts.custom_models_dir
                model_name = "ipcam-general-small" 

            self.log(LogMethod.Info | LogMethod.Server,
            { 
                "filename": __file__,
                "loglevel": "information",
                "method": sys._getframe().f_code.co_name,
                "message": f"Detecting using {model_name}"
            })

            response = do_detect(self, models_dir, model_name, img, threshold)
        
        else:
            self.report_error(None, __file__, f"Unknown command {data.command}")
            response = { "success": False, "error": "unsupported command" }

        return response
            

    def list_models(self, models_path: str):

        """
        Lists the custom models we have in the assets folder. This ignores the 
        yolo* files.
        """

        # We'll only refresh the list of models at most once a minute
        if self.models_last_checked is None or (time() - self.models_last_checked) >= 60:
            self.model_names = [entry.name[:-5] for entry in os.scandir(models_path)
                                            if (entry.is_file()
                                            and entry.name.endswith(".rknn")
                                            and not entry.name.startswith("yolov5"))]
            self.models_last_checked = time()
        
        return { "success": True, "models": self.model_names }


if __name__ == "__main__":
    FastDeploy_adapter().start_loop()
