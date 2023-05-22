﻿using System.IO;
using System.Linq;
using System.Runtime.Serialization;
using System.Text.Json.Serialization;

using CodeProject.AI.SDK.Common;

namespace CodeProject.AI.API.Common
{
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public enum ModuleStatusType
    {
        /// <summary>
        /// No idea what's happening.
        /// </summary>
        [EnumMember(Value = "Unknown")]
        Unknown = 0,

        /// <summary>
        /// Not available. Maybe not valid, maybe not available on this platform.
        /// </summary>
        [EnumMember(Value = "NotAvailable")]
        NotAvailable,

        /// <summary>
        /// Is available to be downloaded and installed on this platform.
        /// </summary>
        [EnumMember(Value = "Available")]
        Available,

        /// <summary>
        /// An update to an already-installed module is available to be downloaded and installed
        /// on this platform.
        /// </summary>
        [EnumMember(Value = "UpdateAvailable")]
        UpdateAvailable,
        
        /// <summary>
        /// Currently downloading from the registry
        /// </summary>
        [EnumMember(Value = "Downloading")]
        Downloading,

        /// <summary>
        /// Unpacking the downloaded model and prepping for install
        /// </summary>
        [EnumMember(Value = "Unpacking")]
        Unpacking,

        /// <summary>
        /// Installing the module
        /// </summary>
        [EnumMember(Value = "Installing")]
        Installing,

        /// <summary>
        /// Tried to install but failed to install in a way that allowed a successful start
        /// </summary>
        [EnumMember(Value = "FailedInstall")]
        FailedInstall,

        /// <summary>
        /// Off to the races
        /// </summary>
        [EnumMember(Value = "Installed")]
        Installed,

        /// <summary>
        /// Stopping and uninstalling this module.
        /// </summary>
        [EnumMember(Value = "Uninstalling")]
        Uninstalling,

        /// <summary>
        /// Tried to uninstall but failed.
        /// </summary>
        [EnumMember(Value = "UninstallFailed")]
        UninstallFailed,

        /// <summary>
        /// Was installed, but no longer. Completely Uninstalled.
        /// </summary>
        [EnumMember(Value = "Uninstalled")]
        Uninstalled
    }

    /// <summary>
    /// A description of a downloadable AI analysis module.
    /// </summary>
    public class ModuleDescription : ModuleBase
    {
        /// <summary>
        /// Gets or sets the URL from where this module can be downloaded. This could be included in
        /// the modules.json file that ultimately populates this object, but more likely this value
        /// will be set by the server at some point.
        /// </summary>
        public string? DownloadUrl { get; set; }

        /// <summary>
        /// Gets or sets the status of this module.
        /// </summary>
        public ModuleStatusType? Status { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether the module represented in this description can
        /// actually be downloaded (as opposed to being sideloaded or uploaded by a user)
        /// </summary>
        public bool IsDownloadable { get; set; } = true;

        /// <summary>
        /// Gets or sets the number of downloads of this module. This could be included in the
        /// modules.json file that ultimately populates this object, but more likely this value
        /// will be set by the server at some point.
        /// </summary>
        public int Downloads { get; set; }

        /// <summary>
        /// Gets or sets the version of this module currently installed. This value is not
        /// deserialised, but instead must be set by the server.
        /// </summary>
        public string? CurrentInstalledVersion { get; set; }

        /// <summary>
        /// Gets or sets the latest version of this module that is compatible with the current
        /// server. This value is not deserialised, but instead must be set by the server.
        /// </summary>
        public string? LatestCompatibleVersion { get; set; }

        /// <summary>
        /// Gets or sets the release date of the latest compatible version of this module
        /// </summary>
        public string? CompatibleVersionReleaseDate { get; set; }

        /// <summary>
        /// Gets a value indicating whether or not this is a valid module that can actually be
        /// started.
        /// </summary>
        public bool Valid
        {
            get
            {
                return !string.IsNullOrWhiteSpace(ModuleId)    &&
                       !string.IsNullOrWhiteSpace(DownloadUrl) &&
                       !string.IsNullOrWhiteSpace(Name)        &&
                       Platforms?.Length > 0;
            }
        }
    }

    /// <summary>
    /// Extension methods for the ModuleDescription class
    /// </summary>
    public static class ModuleDescriptionExtensions
    {
        /// <summary>
        /// ModuleDescription objects are typically created by deserialising a JSON file so we don't
        /// get a chance at create time to supply supplementary information or adjust values that
        /// may not have been set (eg moduleId). Specifically, this function will set the status and
        /// the ModulePath / WorkingDirectory, as well as setting the latest compatible version from
        /// the module's VersionCompatibility list. But this could change without notice.
        /// </summary>
        /// <param name="module">This module that requires initialisation</param>
        /// <param name="currentServerVersion">The current version of the server</param>
        /// <param name="modulesPath">The path to the folder containing all downloaded and installed
        /// modules</param>
        /// <param name="preInstalledModulesPath">The path to the folder containing all pre-installed
        /// modules</param>
        /// <remarks>Modules are usually downloaded and installed in the modulesPAth, but we can
        /// 'pre-install' them in situations like a Docker image. We pre-install modules in a
        /// separate folder than the downloaded and installed modules in order to avoid conflicts 
        /// (in Docker) when a user maps a local folder to the modules dir. Doing this to the 'pre
        /// insalled' dir would make the contents (the preinstalled modules) disappear.</remarks>
        public static void Initialise(this ModuleDescription module, string currentServerVersion, 
                                      string modulesPath, string preInstalledModulesPath)
        {
            // Currently these are unused. There are here only as an experiment
            if (module.PreInstalled)
                module.ModulePath = Path.Combine(preInstalledModulesPath, module.ModuleId!);
            else
                module.ModulePath = Path.Combine(modulesPath, module.ModuleId!);
            module.WorkingDirectory = module.ModulePath; // This once was allowed to be different to ModulePath

            // Find the most recent version of this module that's compatible with the current server
            SetLatestCompatibleVersion(module, currentServerVersion);

            // Set the status of all entries based on availability on this platform
            module.Status = string.IsNullOrWhiteSpace(module.LatestCompatibleVersion) 
                          || !module.IsAvailable(SystemInfo.Platform, currentServerVersion)
                          ? ModuleStatusType.NotAvailable : ModuleStatusType.Available;
        }

        /// <summary>
        /// Gets a value indicating whether or not this module is actually available. This depends 
        /// on having valid commands, settings, and importantly, being supported on this platform.
        /// </summary>
        /// <param name="module">This module</param>
        /// <param name="platform">The platform being tested</param>
        /// <param name="serverVersion">The version of the server, or null to ignore version issues</param>
        /// <returns>true if the module is available; false otherwise</returns>
        public static bool IsAvailable(this ModuleDescription module, string platform, string? serverVersion)
        {
            if (module is null)
                return false;

            // First check: Is there a version of this module that's compatible with the current server?
            if (serverVersion is not null && string.IsNullOrWhiteSpace(module.LatestCompatibleVersion))
                SetLatestCompatibleVersion(module, serverVersion);

            bool versionOK = serverVersion is null || !string.IsNullOrWhiteSpace(module.LatestCompatibleVersion);

            // Second check: Is this module available on this platform?
            return module.Valid && versionOK &&
                   ( module.Platforms!.Any(p => p.EqualsIgnoreCase("all")) ||
                     module.Platforms!.Any(p => p.EqualsIgnoreCase(platform)) );
        }

        private static void SetLatestCompatibleVersion(ModuleDescription module, string currentServerVersion)
        {
            // HACK: To be removed after CPAI 2.1 is released. The Versions array wasn't added to
            // the downloadable list of modules until server version 2.1. All modules pre-server
            // 2.1 are compatible with server 2.1+, so 
            if (module.VersionCompatibililty is null || module.VersionCompatibililty.Count() == 0)
            {
                module.LatestCompatibleVersion      = module.Version;
                module.CompatibleVersionReleaseDate = "2022-03-20";
            }
            else
            {
                foreach (VersionCompatibility version in module.VersionCompatibililty)
                {
                    if (version.ServerVersionRange is null || version.ServerVersionRange.Length < 2)
                        continue;

                    string? minServerVersion = version.ServerVersionRange[0];
                    string? maxServerVersion = version.ServerVersionRange[1];

                    if (string.IsNullOrEmpty(minServerVersion)) minServerVersion = "0.0";
                    if (string.IsNullOrEmpty(maxServerVersion)) maxServerVersion = currentServerVersion;

                    if (VersionInfo.Compare(minServerVersion, currentServerVersion) <= 0 &&
                        VersionInfo.Compare(maxServerVersion, currentServerVersion) >= 0)
                    {
                        if (module.LatestCompatibleVersion is null ||
                            VersionInfo.Compare(module.LatestCompatibleVersion, version.ModuleVersion) <= 0)
                        {
                            module.LatestCompatibleVersion      = version.ModuleVersion;
                            module.CompatibleVersionReleaseDate = version.ReleaseDate;
                        }
                    }
                }
            }
        }
    }
}