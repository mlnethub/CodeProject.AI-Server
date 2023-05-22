# Import our general libraries
import os
import sys
import time

# For PyTorch on Apple silicon
os.environ["PYTORCH_ENABLE_MPS_FALLBACK"] = "1"

# Import the CodeProject.AI SDK. This will add to the PATH var for future imports
sys.path.append("../../SDK/Python")
from common import JSON
from request_data import RequestData
from module_runner import ModuleRunner
from module_logging import LogMethod

# Import the method of the module we're wrapping
from PIL import Image
from options import Options

from detect import init_detect, do_detection


class YOLO62_adapter(ModuleRunner):

    def __init__(self):
        super().__init__()
        self.opts = Options()
        self.models_last_checked = None
        self.model_names         = []  # We'll use this to cache the available model names

    def initialise(self):

        # if the module was launched outside of the server then the queue name 
        # wasn't set. This is normally fine, but here we want the queue to be
        # the same as the other object detection queues
        if not self.launched_by_server:
            self.queue_name = "objectdetection_queue"

        init_detect(self.opts)

        if self.opts.use_CUDA:
            self.execution_provider = "CUDA"
        elif self.opts.use_MPS:
            self.execution_provider = "MPS"

    def process(self, data: RequestData) -> JSON:
        
        response = None

        if data.command == "list-custom":               # list all models available

            # The route to here is /v1/vision/custom/list

            response = self.list_models(self.opts.custom_models_dir)

        elif data.command == "detect":                  # Perform 'standard' object detection

            # The route to here is /v1/vision/detection

            threshold: float = float(data.get_value("min_confidence", "0.4"))
            img: Image       = data.get_image(0)

            response = do_detection(self, self.opts.models_dir,
                                    self.opts.std_model_name, self.opts.resolution_pixels,
                                    self.opts.use_CUDA, self.accel_device_name,
                                    self.opts.use_MPS, self.half_precision, img, threshold)

        elif data.command == "custom":                  # Perform custom object detection

            threshold: float  = float(data.get_value("min_confidence", "0.4"))
            img: Image        = data.get_image(0)

            # The route to here is /v1/vision/custom/<model-name>. if mode-name = general,
            # or no model provided, then a built-in general purpose mode will be used.
            model_dir:str  = self.opts.custom_models_dir
            model_name:str = "general"
            if data.segments and data.segments[0]:
                model_name = data.segments[0]

            # Map the "general" model to our current "general" model

            # if model_name == "general":              # use the standard YOLO model
            #    model_dir  = opts.models_dir
            #    model_name = opts.std_model_name

            if model_name == "general":                # Use the custom IP Cam general model
                model_dir  = self.opts.custom_models_dir
                model_name = "ipcam-general" 

            self.log(LogMethod.Info | LogMethod.Server,
            { 
                "filename": __file__,
                "loglevel": "information",
                "method": sys._getframe().f_code.co_name,
                "message": f"Detecting using {model_name}"
            })

            use_mX_GPU = False # self.opts.use_MPS   - Custom models don't currently work with pyTorch on MPS
            response = do_detection(self, model_dir, model_name, 
                                    self.opts.resolution_pixels, self.opts.use_CUDA,
                                    self.accel_device_name, use_mX_GPU,
                                    self.half_precision, img, threshold)

        else:
            self.report_error(None, __file__, f"Unknown command {data.command}")

        return response


    def list_models(self, models_path: str):

        """
        Lists the custom models we have in the assets folder. This ignores the 
        yolo* files.
        """

        # We'll only refresh the list of models at most once a minute
        if self.models_last_checked is None or (time.time() - self.models_last_checked) >= 60:
            self.model_names = [entry.name[:-3] for entry in os.scandir(models_path)
                                            if (entry.is_file()
                                            and entry.name.endswith(".pt")
                                            and not entry.name.startswith("yolov5"))]
            self.models_last_checked = time.time()

        return { "success": True, "models": self.model_names }


if __name__ == "__main__":
    YOLO62_adapter().start_loop()