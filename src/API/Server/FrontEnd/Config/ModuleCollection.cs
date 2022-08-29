﻿using System;
using System.Collections.Generic;

using CodeProject.AI.Server.Backend;

// TODO: This needs to be available to both the frontend and backend modules so that a single
// version of truth for the module configuration can be read an parsed. Probably should go in the
// Backend library next to the BackendRouteMap class, or possibly in Common.
namespace CodeProject.AI.API.Server.Frontend
{
    /// <summary>
    /// The set of modules for backend processing.
    /// </summary>
    // TODO: because this may be modified by multiple threads, this
    //       probably should be derived from ConcurrentDictionary.
    public class ModuleCollection : Dictionary<string, ModuleConfig>
    {
    }

    /// <summary>
    /// Information required to start the backend processes.
    /// </summary>
    public class ModuleConfig
    {
        /// <summary>
        /// Gets or sets a value indicating whether this procoess should be activated on startup if
        /// no instruction to the contrary is seen. A default "Start me up" flag.
        /// </summary>
        public bool? Activate { get; set; }

        /// <summary>
        /// Gets or sets the Id of the Module
        /// </summary>
        public string? ModuleId { get; set; }

        /// <summary>
        /// Gets or sets the Name to be displayed.
        /// </summary>
        public string? Name { get; set; }

        /// <summary>
        /// Gets or sets the runtime used to execute the file at FilePath. For example, the runtime
        /// could be "dotnet" or "python39". 
        /// </summary>
        public string? Runtime { get; set; }

        /// <summary>
        /// Gets or sets the command to execute the file at FilePath. If set, this overrides Runtime.
        /// An example would be "/usr/bin/python3". This property allows you to specify an explicit
        /// command in case the necessary runtime hasn't been registered, or in case you need to
        /// provide specific flags or naming alternative when executing the FilePath on different
        /// platforms. 
        /// </summary>
        public string? Command { get; set; }

        /*
        /// <summary>
        /// Gets or sets the number of seconds this module should pause after starting to ensure 
        /// any resources that require startup (eg GPUs) are fully activated before moving on.
        /// </summary>
        public int? PostStartPauseSecs { get; set; }
        */

        /// <summary>
        /// Gets or sets the path to the startup file relative to the module directory.
        /// </summary>
        /// <remarks>
        /// If no Runtime or Command is specified then a default runtime will be chosen based on
        /// the extension. Currently this is:
        ///     .py  => it will be started with the default Python interpreter
        ///     .dll => it will be started with the .NET runtime.
        /// </remarks>
        // TODO: this is currently relative to the AnalysisLayer directory but 
        //  should be relative to the directory containing the modulesettings.json file.
        //  This should be changed when the modules read the modulesetings.json files for
        //  their configuration.
        public string? FilePath { get; set; }

        /// <summary>
        /// Gets or sets the path to the working directory file relative to the module directory.
        /// If this is null then the working directory will be set as the directory from FilePath.
        /// </summary>
        public string? WorkingDirectory { get; set; }

        /// <summary>
        /// Gets or sets the name of the configuration value which enables this process.
        /// </summary>
        // TODO: I believe this is no longer used and should be removed
        public string[] EnableFlags { get; set; } = Array.Empty<string>();

        /// <summary>
        /// Gets or sets the information to pass to the backend processes.
        /// </summary>
        public Dictionary<string, object>? EnvironmentVariables { get; set; }

        /// <summary>
        /// Gets or sets a list of RouteMaps.
        /// </summary>
        public ModuleRouteInfo[] RouteMaps { get; set; } = Array.Empty<ModuleRouteInfo>();

        /// <summary>
        /// Gets or sets the platforms on which this module is supported.
        /// </summary>
        public string[] Platforms { get; set; } = Array.Empty<string>();

        /*
        /// <summary>
        /// Gets or sets the name of the hardware acceleration provider.
        /// </summary>
        public string? ExecutionProvider { get; set; }

        /// <summary>
        /// Gets or sets the hardware (chip) identifier
        /// </summary>
        public string? HardwareId { get; set; }
        */
    }
}
