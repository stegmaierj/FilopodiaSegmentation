%%
% FilopodiaSegmentation.
% Copyright (C) 2018 B. Mattes, Y. Dang, S. Scholpp, R. Mikut, J. Stegmaier
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the Liceense at
% 
%     http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
% Please refer to the documentation for more information about the software
% as well as for installation instructions.
%
% If you use this application for your work, please cite the repository and
% the following publication:
%
% Mattes, B., Dang, Y., Greicius, G., Kaufmann, L. T., Prunsche, B., 
% Rosenbauer, J., Stegmaier, J., Mikut, R., Özbek, S., Nienhaus, G. U., 
% Schug, A., Virshup D. M., Scholpp, S., "Wnt/PCP controls spreading of 
% Wnt/β-catenin signals by cytonemes in vertebrates". Elife, 7, e36953, 2018.
%
%%

%% close and clear all previous data
close all;

%% add paths for the live wire and the image reader
if (~isdeployed)
    addpath('../ThirdParty/LiveWire/');
    addpath('../ThirdParty/BioFormats/');
    addpath('../ThirdParty/bresenham/');
    addpath('../ThirdParty/');
end

%% initialize the global settings variable
global settings;

%% project open prompt
choice = questdlg('Would you like to open an existing project?', 'Open existing project?', 'Yes', 'No', 'No');

%% try to load a project file
if (strcmp(choice, 'Yes') == true)
    [projectFile, projectPath] = uigetfile('*.mat', 'Select an existing project or press cancel to start a new project.');
else
    projectFile = 0;
end

if (projectFile ~= 0)
    settings = load([projectPath filesep projectFile]);
    tmpSettings.savePath = [projectPath filesep projectFile];
    settings.dirtyFlag = true;
    
    if (exist(settings.rawImageFileName, 'file'))
        [settings.wntImage, settings.rawImage, ~] = ReadLifImage(settings.rawImageFileName, settings.selectedSeries, settings.wntChannel, settings.memChannel);
    else
        error('Unable to start. Please provide the required input images!'); 
    end
else
    
    settings.rawImageFileName = '';
    settings.edgeImageFileName = '';
    settings.wntImageFileName = '';
    
    %% select the file name
    if (~exist(settings.rawImageFileName, 'file'))
        %[file, folder] = uigetfile({'*.lif', 'LIF-File (*.lif)'; '*.ims', 'IMS-File (*.ims)'; '*.*',  'All Files (*.*)'}, 'Select the raw image stack');
        [file, folder] = uigetfile('*', 'Select the raw image stack');
        settings.rawImageFileName = [folder filesep file];
        if (settings.rawImageFileName == 0)
            disp('Unable to open the selected file!');
        end
    end
    
    if (exist(settings.rawImageFileName, 'file'))
        [settings.wntImage, settings.rawImage, projectSettings] = ReadLifImage(settings.rawImageFileName);
    else
        error('Unable to start. Please provide the required input images!'); 
    end

    settings.selectedSeries = str2double(projectSettings{1});
    settings.wntChannel = str2double(projectSettings{2});
    settings.memChannel = str2double(projectSettings{3});
    settings.xscale = str2double(projectSettings{4});
    settings.yscale = str2double(projectSettings{5});
    settings.zscale = str2double(projectSettings{6});
    settings.useEdgeImage = str2double(projectSettings{7});
    settings.useSingleResultFile = str2double(projectSettings{8});
    settings.currentSlice = 1;
    settings.currentCell = 1;
    settings.fontSize = 15;
    settings.clickType = 'normal';
    settings.markerSize = 15;
    settings.xLim = [];
    settings.yLim = [];
    settings.filopodiaStart = [];
    settings.filopodiaEnd = [];
    settings.useMaximumProjection = false;
    settings.segmentedFilopodia = [];
    settings.selectedFilopodia = 0;
    settings.prevSelectedFilopodia = 0;
    settings.plottedFilopodia = 0;
    settings.previewPadding = 20;
    settings.savePath = '';
    settings.dirtyFlag = true;
end

if (settings.useEdgeImage == true)
    [folder, file, ext] = fileparts(settings.rawImageFileName);
    edgeFileName = [strtrim(strrep(file, ' ', '')) '_Series=' num2str(settings.selectedSeries)];
    
    if (ispc == true)
        tempDir = 'Temp/';
    else
        tempDir = '/tmp/';
    end
    
    if (~exist([tempDir 'item_0008_DiscreteGaussianImageFilter/' edgeFileName '_DiscreteGaussianImageFilter_Out1.tif'], 'file'))
        
        if (ispc == true && ~exist('Temp/', 'dir'))
            mkdir('Temp/');
        end
        
        if (exist([tempDir edgeFileName '.tif'], 'file'))
            delete([tempDir edgeFileName '.tif']);
        end
        for i=1:size(settings.rawImage, 3)
            imwrite(im2uint8(settings.rawImage(:,:,i)), [tempDir edgeFileName '.tif'], 'WriteMode', 'append');
        end

        %% perform instance segmentation using XPIWIT (seeded watershed)
        previousPath = pwd;
        if (ispc)
            cd ..\ThirdParty\XPIWIT\Windows\
        elseif (ismac)
            cd ../ThirdParty/XPIWIT/macOS/
        elseif (isunix)
            cd ../ThirdParty/XPIWIT/Linux/
        end

        %% specify the XPIWIT command
        XPIWITCommand1 = ['./XPIWIT.sh ' ...
            '--output "' tempDir '" ' ...
            '--input "0, ' [tempDir edgeFileName '.tif'] ', 3, float" ' ...
            '--xml "../EdgeEnhancement.xml" ' ...
            '--seed 0 --lockfile off --subfolder "filterid, filtername" --outputformat "imagename, filtername" --end'];

        %% replace slashes by backslashes for windows systems
        if (ispc == true)
            XPIWITCommand1 = strrep(XPIWITCommand1, './XPIWIT.sh', 'XPIWIT.exe');
            XPIWITCommand1 = strrep(XPIWITCommand1, '\', '/');
        end
        system(XPIWITCommand1);
        cd(previousPath);
        
        
%         templateFile = fopen('EdgeEnhancementTemplate.txt', 'rb');
%         outputFile = fopen('EdgeEnhancement.txt', 'wb');
% 
%         tline = fgets(templateFile);
%         while ischar(tline)
%             tline = strrep(tline, '%OUTPUTPATH%', tempDir);
%             tline = strrep(tline, '%INPUTFILE%', [tempDir edgeFileName '.tif']);
%             fprintf(outputFile, tline);
%             tline = fgets(templateFile);
%         end
% 
%         fclose(templateFile);
%         fclose(outputFile);
%         if (ispc == true)
%             system('XPIWIT.exe < EdgeEnhancement.txt');
%         else
%             system('./XPIWIT.sh < EdgeEnhancement.txt');
%         end
    end
    settings.edgeImage = zeros(size(settings.rawImage));
    for i=1:size(settings.rawImage, 3)
        settings.edgeImage(:,:,i) = im2double(imread([tempDir 'item_0008_DiscreteGaussianImageFilter/' edgeFileName '_DiscreteGaussianImageFilter_Out1.tif'], i));
    end
else
    settings.edgeImage = settings.rawImage;
end

%% initialize the main figure
settings.mainFigure = figure;
settings.mainAxes = axes('parent', settings.mainFigure, 'unit', 'normalized', 'position', [0,0,0.5,1.0]);
settings.closeupXYAxes = axes('parent', settings.mainFigure, 'unit', 'normalized', 'position', [0.5,0.5,0.25,0.5]);
settings.closeupZAxes = axes('parent', settings.mainFigure, 'unit', 'normalized', 'position', [0.75,0.5,0.25,0.5]);
settings.closeupXYWntAxes = axes('parent', settings.mainFigure, 'unit', 'normalized', 'position', [0.5,0.0,0.25,0.5]);
settings.statsAxes = axes('parent', settings.mainFigure, 'unit', 'normalized', 'position', [0.75,0.0,0.25,0.5]);
set(gcf, 'renderer', 'opengl');
set(settings.mainFigure,'WindowButtonDownFcn',@MouseDown);
set(settings.mainFigure,'WindowButtonUpFcn', @MouseUp);
set(settings.mainFigure, 'KeyReleaseFcn', @KeyRelease);
set(zoom(settings.mainFigure), 'ActionPostCallback', @ZoomCorrection);
set(pan(settings.mainFigure), 'ActionPostCallback', @PanCorrection);
set(settings.mainFigure, 'WindowScrollWheelFcn', @WheelFunction);
set(settings.mainFigure, 'ResizeFcn', 'global settings; settings.dirtyFlag=true; UpdateVisualization;');
set(settings.mainFigure,'units','normalized','outerposition',[0 0 1 1])

%% update the visualization
UpdateVisualization;
colordef black; %#ok<COLORDEF>
set(gcf, 'Color', 'black');
axis equal;
colormap gray;