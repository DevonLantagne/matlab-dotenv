% This script downloads the most recent commit of dotenv.m from GitHub.
%   Downloads from the author's public repo.
%
%   This script will create a folder "dotenv" in the current working
%   directory and place the dotenv.m file inside.

% Define target folder and files to be downloaded
targetFolder = 'dotenv';
files = ["dotenv.m", "readme.md"];

targetDir = fullfile(pwd, targetFolder);
gitHubURL = "https://raw.githubusercontent.com/DevonLantagne/matlab-dotenv/main/";

fprintf("Saving dotenv to %s\nDon't forget to add this folder to the MATLAB path!\n", targetDir);

% Create directory if it doesn't exist
if ~exist(targetDir, 'dir')
    mkdir(targetDir);
end

% Download the files

for file = files
    localFile = fullfile(targetDir, file);
    remoteURL = gitHubURL + file;

    fprintf('Downloading %s from: %s\n', file, remoteURL);

    try
        websave(localFile, remoteURL);
        fprintf('  ✔ Saved\n');
    catch ME
        warning('  ✘ Failed to download %s: %s\n', localFile, ME.message);
    end
end

fprintf("File download complete!\n\n");