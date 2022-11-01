﻿using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;

using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.ML.OnnxRuntime;

using SkiaSharp;
using Yolov5Net.Scorer;
using Yolov5Net.Scorer.Models;

using CodeProject.AI.AnalysisLayer.SDK;
using System.Linq;

namespace CodeProject.AI.AnalysisLayer.ObjectDetection.Yolo
{
    /// <summary>
    /// An Object Detection Prediction.
    /// </summary>
    public class DetectionPrediction : BoundingBoxPrediction
    {
        public string? label { get; set; }
    }

    /// <summary>
    /// An Object Detection Response.
    /// </summary>
    public class BackendObjectDetectionResponse : BackendSuccessResponse
    {
        public DetectionPrediction[]? predictions { get; set; }
    }

    /// <summary>
    /// An YoloV5 object detector.
    /// </summary>
    public class ObjectDetector
    {
        private readonly YoloScorer<YoloCocoP5Model>? _scorer = null;
        private readonly ILogger<ObjectDetector>      _logger;

        /// <summary>
        /// Gets or sets the execution provider.
        /// </summary>
        public string ExecutionProvider { get; set; } = "CPU";

        /// <summary>
        /// Gets or sets the hardware type (CPU or GPU).
        /// </summary>
        public string HardwareType { get; set; } = "CPU";

        public ObjectDetector(IConfiguration config, IHostEnvironment env, ILogger<ObjectDetector> logger)
        {
            _logger = logger;

            string path = Directory.GetCurrentDirectory(); // AppContext.BaseDirectory;

            string mode = config.GetValue<string>("MODEL_SIZE");
            string modelPath = (mode ?? string.Empty.ToLower()) switch
            {
                "large"  => "assets/yolov5m.onnx",
                "medium" => "assets/yolov5s.onnx",
                "small"  => "assets/yolov5n.onnx",
                "tiny"   => "assets/yolov5n.onnx",
                _        => "assets/yolov5s.onnx"
            };

            try
            {
                string modelFilePath = Path.Combine(path, modelPath);
                var modelFileInfo = new FileInfo(modelFilePath);
                SessionOptions sessionOpts = GetHardwareInfo();

                if (modelFileInfo.Exists)
                {
                    try
                    {
                        _scorer = new YoloScorer<YoloCocoP5Model>(modelFilePath, sessionOpts);
                    }
                    catch // something went wrong, probably the device is too old and no longer supported.
                    {
                        // fall back to CPU only
                        _logger.LogError($"Unable to load the model with {ExecutionProvider}. Falling back to CPU.");
                        _scorer = new YoloScorer<YoloCocoP5Model>(modelFilePath);

                        ExecutionProvider = "CPU";
                        HardwareType      = "CPU";
                    }
                }
                else
                    _logger.LogError("Unable to load the model at " + modelFilePath);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Unable to initialise the YOLO scorer");
            }
        }

        private SessionOptions GetHardwareInfo()
        {
            var sessionOpts = new SessionOptions();

            bool supportGPU = (Environment.GetEnvironmentVariable("CPAI_MODULE_SUPPORT_GPU") ?? "false").ToLower() == "true";
            if (supportGPU)
            {
                string[]? providers = null;
                try
                {
                    providers = OrtEnv.Instance().GetAvailableProviders();
                }
                catch
                {
                }

                // Enable CUDA  -------------------
                if (providers?.Any(p => p.StartsWith("CUDA", StringComparison.OrdinalIgnoreCase)) ?? false)
                {
                    try
                    {
                        sessionOpts.AppendExecutionProvider_CUDA();

                        ExecutionProvider = "CUDA";
                        HardwareType      = "GPU";
                    }
                    catch
                    {
                        // do nothing, the provider didn't work so keep going
                    }
                }

                // Enable OpenVINO -------------------
                if (providers?.Any(p => p.StartsWith("OpenVINO", StringComparison.OrdinalIgnoreCase)) ?? false)
                {
                    try
                    {
                        sessionOpts.AppendExecutionProvider_OpenVINO("GPU_FP16");
                        //sessionOpts.EnableMemoryPattern = false;
                        //sessionOpts.ExecutionMode = ExecutionMode.ORT_PARALLEL;

                        ExecutionProvider = "OpenVINO";
                        HardwareType      = "GPU";
                    }
                    catch
                    {
                        // do nothing, the provider didn't work so keep going
                    }
                }

                // Enable DirectML -------------------
                if (providers?.Any(p => p.StartsWith("DML", StringComparison.OrdinalIgnoreCase)) ?? false)
                {
                    try
                    {
                        sessionOpts.AppendExecutionProvider_DML();
                        sessionOpts.EnableMemoryPattern    = false;
                        sessionOpts.ExecutionMode          = ExecutionMode.ORT_SEQUENTIAL;
                        sessionOpts.GraphOptimizationLevel = GraphOptimizationLevel.ORT_DISABLE_ALL;

                        ExecutionProvider = "DirectML";
                        HardwareType      = "GPU";
                    }
                    catch
                    {
                        // do nothing, the provider didn't work so keep going
                    }
                }
            }

            sessionOpts.AppendExecutionProvider_CPU();
            return sessionOpts;
        }

        /// <summary>
        /// Predicts the objects in an image file.
        /// </summary>
        /// <param name="filename">The filename of the image.</param>
        /// <returns>The predicted objects with bounding boxes and confidences.</returns>
        public List<YoloPrediction>? Predict(string filename)
        {
            var fi = new FileInfo(filename);
            if (!fi.Exists)
                return null;

            using SKImage? image = GetImage(filename);
            List<YoloPrediction>? predictions = Predict(image);

            return predictions;
        }

        /// <summary>
        /// Predicts the objects in an image.
        /// </summary>
        /// <param name="image"></param>
        /// <returns>The predicted objects with bounding boxes and confidences.</returns>
        public List<YoloPrediction>? Predict(SKImage? image)
        {
            if (image == null)
                return null;

            if (_scorer is null)
                return null;

            try
            {
                return _scorer.Predict(image);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unable to run prediction");
                return null;
            }
        }

        public List<YoloPrediction>? Predict(byte[]? imageData)
        {
            if (imageData == null)
                return null;

            var image = GetImage(imageData);

            try
            {
                return _scorer?.Predict(image);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unable to run prediction");
                return null;
            }
        }

        /// <summary>
        /// Loads a Bitmap from a file.
        /// </summary>
        /// <param name="filename">The file name.</param>
        /// <returns>The Bitmap, or null.</returns>
        /// <remarks>SkiSharp handles more image formats than System.Drawing.</remarks>
        private SKImage? GetImage(string filename)
        {
            // TODO: Add error handling and port this to Maui
            var skiaImage = SKImage.FromEncodedData(filename);
            if (skiaImage is null)
                return null;

            return skiaImage; //.ToBitmap();
        }

        private SKImage? GetImage(byte[] imageData)
        {
            var skiaImage = SKImage.FromEncodedData(imageData);
            if (skiaImage is null)
                return null;

            return skiaImage; //.ToBitmap();
        }
    }
}
