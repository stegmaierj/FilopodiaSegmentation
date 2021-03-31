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

global settings;

%% get input filename
% if (~isfield(settings, 'projectFileName') || ~exist(settings.projectFileName, 'file'))
%     [fileName, pathName, filterIndex] = uiputfile('*.mat', 'Save Project As ...');
%     settings.projectFileName = [pathName fileName];
% end

%% check if filename exists
if (isfield(settings, 'projectFileName') && ~isempty(settings.projectFileName))
    disp('Saving project ...');
    
    %% temporarily remove the handles and images for saving
    tmpRFPAxes = settings.rfpAxes;
    settings.rfpAxes = [];
    tmpFigureHandle = settings.mainFigure;
    settings.mainFigure = [];
    tmpImageHandle = settings.imageHandle;
    settings.imageHandle = [];
    
    %% save the project
    save(settings.projectFileName, '-v7.3', 'settings');
    
    try
        
    %% export the csv files
    summaryTableCellArray = cell(settings.numImages+1, 4);
    summaryTableCellArray{1,1} = 'Image Name';
    summaryTableCellArray{1,2} = 'Number of Cells';
    summaryTableCellArray{1,3} = 'Number of Filopodia';
    summaryTableCellArray{1,4} = 'Average Length of Filopodia';
    summaryTableCellArray{1,5} = 'Minimum Length';
    summaryTableCellArray{1,6} = 'Maximum Length';
    summaryTableCellArray{1,7} = 'Number of Wnt-Positive Filopodia';
    summaryTable = zeros(settings.numImages, 7);
    
    for i=1:settings.numImages
        
        numCells = 1;
        numFilopodiaCurrentCell = 0;
        averageLengthCurrentCell = 0;
        minLengthCurrentCell = inf;
        maxLengthCurrentCell = 0;
        numWntPositiveCells = 0;
        resultTable = zeros(0,6);
        numFilopodia = 0;
        
        filopodiaPerCell = struct();
        filopodiaPerCell(1).numFilopodia = 0;
        filopodiaPerCell(1).numNegativeFilopodia = 0;
        filopodiaPerCell(1).numCytonemes = 0;
        filopodiaPerCell(1).averageLengthFilopodia = 0;
        filopodiaPerCell(1).averageLengthNegativeFilopodia = 0;
        filopodiaPerCell(1).averageLengthCytonemes = 0;
        filopodiaPerCell(1).minLengthFilopodia = inf;
        filopodiaPerCell(1).minLengthNegativeFilopodia = inf;
        filopodiaPerCell(1).minLengthCytonemes = inf;
        filopodiaPerCell(1).maxLengthFilopodia = 0;
        filopodiaPerCell(1).maxLengthNegativeFilopodia = 0;
        filopodiaPerCell(1).maxLengthCytonemes = 0;
        filopodiaPerCell(1).averageFilopodiaGFPIntensity = 0;
        filopodiaPerCell(1).averageFilopodiaRFPIntensity = 0;
        filopodiaPerCell(1).averageCytonemesGFPIntensity = 0;
        filopodiaPerCell(1).averageCytonemesRFPIntensity = 0;
        filopodiaPerCell(1).averageNegativeFilopodiaGFPIntensity = 0;
        filopodiaPerCell(1).averageNegativeFilopodiaRFPIntensity = 0;
                    
        for j=1:length(settings.currentFilopodia{i})
            if (isfield(settings.currentFilopodia{i}(j), 'positions') && ~isempty(settings.currentFilopodia{i}(j).positions))
                %% update the average statistics values
                numCells = max(numCells, settings.currentFilopodia{i}(j).cellId);
                numFilopodiaCurrentCell = numFilopodiaCurrentCell + 1;
                averageLengthCurrentCell = averageLengthCurrentCell + settings.pixelToMicrons * settings.currentFilopodia{i}(j).length;
                minLengthCurrentCell = min(minLengthCurrentCell, settings.pixelToMicrons * settings.currentFilopodia{i}(j).length);
                maxLengthCurrentCell = max(maxLengthCurrentCell, settings.pixelToMicrons * settings.currentFilopodia{i}(j).length);
                if (settings.currentFilopodia{i}(j).gfpIntensity > settings.wntPositiveThreshold)
                    numWntPositiveCells = numWntPositiveCells + 1;
                end
                resultTable(j, :) = [numFilopodiaCurrentCell, settings.currentFilopodia{i}(j).cellId, settings.pixelToMicrons * settings.currentFilopodia{i}(j).length, settings.currentFilopodia{i}(j).rfpIntensity, settings.currentFilopodia{i}(j).gfpIntensity, settings.currentFilopodia{i}(j).gfpIntensity > settings.wntPositiveThreshold];
                
                %% update the per cell results
                currentCell = settings.currentFilopodia{i}(j).cellId;
                if (currentCell > length(filopodiaPerCell))
                    filopodiaPerCell(currentCell).numFilopodia = 0;
                    filopodiaPerCell(currentCell).numNegativeFilopodia = 0;
                    filopodiaPerCell(currentCell).numCytonemes = 0;
                    filopodiaPerCell(currentCell).averageLengthFilopodia = 0;
                    filopodiaPerCell(currentCell).averageLengthNegativeFilopodia = 0;
                    filopodiaPerCell(currentCell).averageLengthCytonemes = 0;
                    filopodiaPerCell(currentCell).minLengthFilopodia = inf;
                    filopodiaPerCell(currentCell).minLengthNegativeFilopodia = inf;
                    filopodiaPerCell(currentCell).minLengthCytonemes = inf;
                    filopodiaPerCell(currentCell).maxLengthFilopodia = 0;
                    filopodiaPerCell(currentCell).maxLengthNegativeFilopodia = 0;
                    filopodiaPerCell(currentCell).maxLengthCytonemes = 0;
                    filopodiaPerCell(currentCell).averageFilopodiaGFPIntensity = 0;
                    filopodiaPerCell(currentCell).averageFilopodiaRFPIntensity = 0;
                    filopodiaPerCell(currentCell).averageCytonemesGFPIntensity = 0;
                    filopodiaPerCell(currentCell).averageCytonemesRFPIntensity = 0;
                    filopodiaPerCell(currentCell).averageNegativeFilopodiaGFPIntensity = 0;
                    filopodiaPerCell(currentCell).averageNegativeFilopodiaRFPIntensity = 0;
                end
                
                filopodiaPerCell(currentCell).numFilopodia = filopodiaPerCell(currentCell).numFilopodia+1;
                filopodiaPerCell(currentCell).averageLengthFilopodia = filopodiaPerCell(currentCell).averageLengthFilopodia+settings.currentFilopodia{i}(j).length;
                filopodiaPerCell(currentCell).averageFilopodiaGFPIntensity = filopodiaPerCell(currentCell).averageFilopodiaGFPIntensity + settings.currentFilopodia{i}(j).gfpIntensity;
                filopodiaPerCell(currentCell).averageFilopodiaRFPIntensity = filopodiaPerCell(currentCell).averageFilopodiaRFPIntensity + settings.currentFilopodia{i}(j).rfpIntensity;
                
                filopodiaPerCell(currentCell).minLengthFilopodia = min(filopodiaPerCell(currentCell).minLengthFilopodia, settings.currentFilopodia{i}(j).length);
                filopodiaPerCell(currentCell).maxLengthFilopodia = max(filopodiaPerCell(currentCell).maxLengthFilopodia, settings.currentFilopodia{i}(j).length);
                
                if (settings.currentFilopodia{i}(j).gfpIntensity >  settings.wntPositiveThreshold)
                    filopodiaPerCell(currentCell).numCytonemes = filopodiaPerCell(currentCell).numCytonemes+1;
                    filopodiaPerCell(currentCell).averageLengthCytonemes = filopodiaPerCell(currentCell).averageLengthCytonemes + settings.currentFilopodia{i}(j).length;
                    filopodiaPerCell(currentCell).averageCytonemesGFPIntensity = filopodiaPerCell(currentCell).averageCytonemesGFPIntensity + settings.currentFilopodia{i}(j).gfpIntensity;
                    filopodiaPerCell(currentCell).averageCytonemesRFPIntensity = filopodiaPerCell(currentCell).averageCytonemesRFPIntensity+ settings.currentFilopodia{i}(j).rfpIntensity;
                    filopodiaPerCell(currentCell).minLengthCytonemes = min(filopodiaPerCell(currentCell).minLengthCytonemes, settings.currentFilopodia{i}(j).length);
                    filopodiaPerCell(currentCell).maxLengthCytonemes = max(filopodiaPerCell(currentCell).maxLengthCytonemes, settings.currentFilopodia{i}(j).length);
                else
                    filopodiaPerCell(currentCell).numNegativeFilopodia = filopodiaPerCell(currentCell).numNegativeFilopodia+1;
                    filopodiaPerCell(currentCell).averageLengthNegativeFilopodia = filopodiaPerCell(currentCell).averageLengthNegativeFilopodia+settings.currentFilopodia{i}(j).length;
                    filopodiaPerCell(currentCell).averageNegativeFilopodiaGFPIntensity = filopodiaPerCell(currentCell).averageNegativeFilopodiaGFPIntensity + settings.currentFilopodia{i}(j).gfpIntensity;
                    filopodiaPerCell(currentCell).averageNegativeFilopodiaRFPIntensity = filopodiaPerCell(currentCell).averageNegativeFilopodiaRFPIntensity + settings.currentFilopodia{i}(j).rfpIntensity;
                    filopodiaPerCell(currentCell).minLengthNegativeFilopodia = min(filopodiaPerCell(currentCell).minLengthNegativeFilopodia, settings.currentFilopodia{i}(j).length);
                    filopodiaPerCell(currentCell).maxLengthNegativeFilopodia = max(filopodiaPerCell(currentCell).maxLengthNegativeFilopodia, settings.currentFilopodia{i}(j).length);
                end
            end
        end
        
        %% correct the average lengths
        for j=1:numCells
            filopodiaPerCell(j).averageLengthFilopodia = filopodiaPerCell(j).averageLengthFilopodia / filopodiaPerCell(j).numFilopodia;
            filopodiaPerCell(j).averageLengthNegativeFilopodia = filopodiaPerCell(j).averageLengthNegativeFilopodia / filopodiaPerCell(j).numNegativeFilopodia;
            filopodiaPerCell(j).averageLengthCytonemes = filopodiaPerCell(j).averageLengthCytonemes / filopodiaPerCell(j).numCytonemes;
            
            filopodiaPerCell(j).averageLengthFilopodiaMicrons = settings.pixelToMicrons * filopodiaPerCell(j).averageLengthFilopodia; 
            filopodiaPerCell(j).averageLengthNegativeFilopodiaMicrons = settings.pixelToMicrons * filopodiaPerCell(j).averageLengthNegativeFilopodia;
            filopodiaPerCell(j).averageLengthCytonemesMicrons = settings.pixelToMicrons * filopodiaPerCell(j).averageLengthCytonemes;
            
            filopodiaPerCell(j).averageFilopodiaGFPIntensity = filopodiaPerCell(j).averageFilopodiaGFPIntensity / filopodiaPerCell(j).numFilopodia;
            filopodiaPerCell(j).averageFilopodiaRFPIntensity = filopodiaPerCell(j).averageFilopodiaRFPIntensity / filopodiaPerCell(j).numFilopodia;
            filopodiaPerCell(j).averageCytonemesGFPIntensity = filopodiaPerCell(j).averageCytonemesGFPIntensity / filopodiaPerCell(j).numCytonemes;
            filopodiaPerCell(j).averageCytonemesRFPIntensity = filopodiaPerCell(j).averageCytonemesRFPIntensity / filopodiaPerCell(j).numCytonemes;
            filopodiaPerCell(j).averageNegativeFilopodiaGFPIntensity = filopodiaPerCell(j).averageNegativeFilopodiaGFPIntensity / filopodiaPerCell(j).numNegativeFilopodia;
            filopodiaPerCell(j).averageNegativeFilopodiaRFPIntensity = filopodiaPerCell(j).averageNegativeFilopodiaRFPIntensity / filopodiaPerCell(j).numNegativeFilopodia;
        end
        
        %% write the individual cell statistics
        cellSummaryTableCellArray = cell(numCells, 4);
        cellSummaryTableCellArray{1,1} = 'Image Name';
        cellSummaryTableCellArray{1,2} = 'Number of Cell';
        cellSummaryTableCellArray{1,3} = 'Total Number of Filopodia';
        cellSummaryTableCellArray{1,4} = 'Average Length of Filopodia';
        cellSummaryTableCellArray{1,5} = 'Minimum Length of Filopodia (µm)';
        cellSummaryTableCellArray{1,6} = 'Maximum Length of Filopodia (µm)';
        cellSummaryTableCellArray{1,7} = 'Average Intensity GFP of Filopodia (a.u.)';
        cellSummaryTableCellArray{1,8} = 'Number of Wnt-Negative Filopodia';
        cellSummaryTableCellArray{1,9} = 'Average Length of Wnt-Negative Filopodia';
        cellSummaryTableCellArray{1,10} = 'Minimum Length (µm)';
        cellSummaryTableCellArray{1,11} = 'Maximum Length (µm)';
        cellSummaryTableCellArray{1,12} = 'Average Intensity GFP of Wnt-Negative Filopodia (a.u.)';
        cellSummaryTableCellArray{1,13} = 'Number of Cytonemes';
        cellSummaryTableCellArray{1,14} = 'Average Length of Cytonemes';
        cellSummaryTableCellArray{1,15} = 'Minimum Length (µm)';
        cellSummaryTableCellArray{1,16} = 'Maximum Length (µm)';
        cellSummaryTableCellArray{1,17} = 'Average Intensity GFP of Cytonemes (a.u.)';
        cellSummaryTableCellArray{1,18} = 'Wnt Threshold';
        cellSummaryTableCellArray{1,19} = 'Cluster Radius';
        cellSummaryTableCellArray{1,20} = 'Pixel To Microns Factor';
        
        %% extract the current image file name
        [path, file, ext] = fileparts(settings.rfpImageFileNames(i+2).name);
        [projectPath, ~, ~] = fileparts(settings.projectFileName);
        imagename = [file ext];
                
        %% fill the cell overview
        for j=1:numCells
            cellSummaryTableCellArray{j+1, 1} = imagename;
            cellSummaryTableCellArray{j+1, 2} = j;
            cellSummaryTableCellArray{j+1, 3} = filopodiaPerCell(j).numFilopodia;
            cellSummaryTableCellArray{j+1, 4} = settings.pixelToMicrons * filopodiaPerCell(j).averageLengthFilopodia;
            cellSummaryTableCellArray{j+1, 5} = settings.pixelToMicrons * filopodiaPerCell(j).minLengthFilopodia;
            cellSummaryTableCellArray{j+1, 6} = settings.pixelToMicrons * filopodiaPerCell(j).maxLengthFilopodia;
            cellSummaryTableCellArray{j+1, 7} = filopodiaPerCell(j).averageFilopodiaGFPIntensity;
            
            cellSummaryTableCellArray{j+1, 8} = filopodiaPerCell(j).numNegativeFilopodia;
            cellSummaryTableCellArray{j+1, 9} = settings.pixelToMicrons * filopodiaPerCell(j).averageLengthNegativeFilopodia;
            cellSummaryTableCellArray{j+1, 10} = settings.pixelToMicrons * filopodiaPerCell(j).minLengthNegativeFilopodia;
            cellSummaryTableCellArray{j+1, 11} = settings.pixelToMicrons * filopodiaPerCell(j).maxLengthNegativeFilopodia;
            cellSummaryTableCellArray{j+1, 12} = filopodiaPerCell(j).averageNegativeFilopodiaGFPIntensity;
            
            cellSummaryTableCellArray{j+1, 13} = filopodiaPerCell(j).numCytonemes;
            cellSummaryTableCellArray{j+1, 14} = settings.pixelToMicrons * filopodiaPerCell(j).averageLengthCytonemes;
            cellSummaryTableCellArray{j+1, 15} = settings.pixelToMicrons * filopodiaPerCell(j).minLengthCytonemes;
            cellSummaryTableCellArray{j+1, 16} = settings.pixelToMicrons * filopodiaPerCell(j).maxLengthCytonemes;
            cellSummaryTableCellArray{j+1, 17} = filopodiaPerCell(j).averageCytonemesGFPIntensity;
            cellSummaryTableCellArray{j+1, 18} = settings.wntPositiveThreshold;
            cellSummaryTableCellArray{j+1, 19} = settings.clusterRadius{i};
            cellSummaryTableCellArray{j+1, 20} = settings.pixelToMicrons;
        end
        
        if (isunix)
           fileID = fopen([projectPath filesep file '_CellSummary.csv'], 'wb');
           for j=1:size(cellSummaryTableCellArray,1)
               for k=1:size(cellSummaryTableCellArray,2)
                    if (j==1 || k==1)
                        fprintf(fileID, '%s;', cellSummaryTableCellArray{j,k});
                    else
                        fprintf(fileID, '%.2f;', cellSummaryTableCellArray{j,k});
                    end                   
               end
               
               fprintf(fileID, '\n');
           end
           fclose(fileID);           
        else
            if (exist([projectPath filesep file '_CellSummary.csv'],'file'))
                delete([projectPath filesep file '_CellSummary.csv']);
            end
            xlswrite([projectPath filesep file '_CellSummary.csv'], cellSummaryTableCellArray);
        end
        
        if (numFilopodiaCurrentCell == 0)
            numCells = 0;
            minLengthCurrentCell = 0;
        end
        
        if (isunix)
            summaryTableCellArray{i+1,1} = imagename;
            summaryTableCellArray{i+1,2} = numCells;
            summaryTableCellArray{i+1,3} = numFilopodiaCurrentCell;
            summaryTableCellArray{i+1,4} = (averageLengthCurrentCell / numFilopodiaCurrentCell);
            summaryTableCellArray{i+1,5} = minLengthCurrentCell;
            summaryTableCellArray{i+1,6} = maxLengthCurrentCell;
            summaryTableCellArray{i+1,7} = numWntPositiveCells;
        else
            summaryTableCellArray{i+1,1} = imagename;
            summaryTableCellArray{i+1,2} = numCells;
            summaryTableCellArray{i+1,3} = numFilopodiaCurrentCell;
            summaryTableCellArray{i+1,4} = (averageLengthCurrentCell / numFilopodiaCurrentCell);
            summaryTableCellArray{i+1,5} = minLengthCurrentCell;
            summaryTableCellArray{i+1,6} = maxLengthCurrentCell;
            summaryTableCellArray{i+1,7} = numWntPositiveCells;
            
            if (exist(strrep(settings.projectFileName, '.mat', '_Summary.xls'),'file'))
                delete(strrep(settings.projectFileName, '.mat', '_Summary.xls'));
            end
            xlswrite(strrep(settings.projectFileName, '.mat', '_Summary.xls'), summaryTableCellArray);
        end
        
        if (~isempty(resultTable))
            if (isunix)
                csvFileName = [projectPath filesep file '_DetectedFilopodia.csv'];
                if (exist(csvFileName, 'file'))
                   delete(csvFileName);
                end
                dlmwrite(csvFileName, resultTable, ';', 0, 0);
                featureNames = '';
                for j=1:size(resultTable,2)
                    featureNames = [featureNames settings.featureNames{j} ';'];
                end
                prepend2file(featureNames, csvFileName, true);
            else
                outputMatrix = settings.featureNames;
                
                for j=1:size(resultTable,1)
                    for k=1:size(resultTable,2)
                        outputMatrix{j+1,k} = resultTable(j,k);
                    end
                end
                
                if (exist([projectPath filesep file '_DetectedFilopodia.xls'],'file'))
                    delete([projectPath filesep file '_DetectedFilopodia.xls'])
                end
                xlswrite([projectPath filesep file '_DetectedFilopodia.xls'], outputMatrix);
            end
        end
        
        if (isunix)
            csvFileNameSummary = strrep(settings.projectFileName, '.mat', '.csv');
            if (exist(csvFileNameSummary, 'file'))
                delete(csvFileNameSummary);
            end
            
            fileID = fopen(csvFileNameSummary, 'wb');
            for j=1:size(summaryTableCellArray,1)
                for k=1:size(summaryTableCellArray,2)
                    if (j==1 || k==1)
                        fprintf(fileID, '%s;', summaryTableCellArray{j,k});
                    else
                        fprintf(fileID, '%.2f;', summaryTableCellArray{j,k});
                    end
                end
                fprintf(fileID, '\n');
            end
            fclose(fileID);
            %prepend2file('Image Name;Number of Cells;Number of Filopodia;Average Length of Filopodia (µm);Minimum Length (µm);Maximum Length (µm);Number of Wnt-Positive Filopodia;', csvFileNameSummary, true);
        end
    end
    
    catch
       disp('Saving the results was not successful!'); 
    end
    
    %% restore deletec variables
    settings.rfpAxes = tmpRFPAxes;
    settings.mainFigure = tmpFigureHandle;
    settings.imageHandle = tmpImageHandle;
    
    disp(['Project successfully saved to: ' settings.projectFileName]);
else
    disp('Invalid filename! Skipping save project.');
end