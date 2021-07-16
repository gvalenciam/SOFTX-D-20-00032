%-----------------MEANDER STATISTICS TOOLBOX. MStaT------------------------
%
% Meander Statistics Toolbox (MStaT), is a packaging of codes developed on 
% MATLAB, which allows the quantification of parameters dexscriptors of 
% meandering channels (sinuosity, arc-wavelength, amplitude, curvature, 
% inflection point, among other). To obtain all the meander parameters  
% MStaT uses the  function of wavelet transform to decompose the signail 
% (centerline). The toolbox obtains the Wavelet Spectrum, Curvature and 
% Angle Variation and the Global Wavelet Spectrum. The input data to use 
% MStaT is the Centerline (in a Coordinate System) and the average Width of 
% the study Channels. MStaT can analize a large number of bends in a short 
% calculation time. Also MStaT allows calculate the migration of a period, 
% and analyzes the migration signature. Finally MStaT has a Confluence
% Module that allow calculate the influence due the presence of the 
% tributary channel on the main channel. 

%% Collaborations
% Lucas Dominguez. UNL, Argentina
% Kensuke Naito. UTEC, Peru
% Jorge Abad. UTEC, Peru
% Ronald Gutierrez. Universidad Pontificia de Peru
%
% Citation: (In progress)
% Meander Statistics Toolbox (MStaT): A Toolbox for Geometry 
% Characterization of Bends in Large Meandering Channels
% Dominguez Ruben, L., Naito, K., Gutierrez, R. R., Szupiany, R. 
% and Abad, J. D.

%--------------------------------------------------------------------------

%      Begin initialization code - DO NOT EDIT.

function varargout = mStat(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mStat_OpeningFcn, ...
                   'gui_OutputFcn',  @mStat_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);               
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end
% If ERROR, write a txt file with the error dump info
try
    
if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
catch err
    if isdeployed
        errLogFileName = fullfile(pwd,...
            ['errorLog' datestr(now,'yyyymmddHHMMSS') '.txt']);
        msgbox({['An unexpected error occurred. Error code: ' err.identifier];...
            ('Error details are being written to the following file: ');...
            errLogFileName},...
            'MStaT Status: Unexpected Error',...
            'error');
        fid = fopen(errLogFileName,'W');
        fwrite(fid,err.getReport('extended','hyperlinks','off'));
        fclose(fid);
        rethrow(err)
    else
        close force
        msgbox(['An unexpected error occurred. Error code: ' err.identifier],...
            'MStaT Status: Unexpected Error',...
            'error');
        rethrow(err);
    end
end

%--------------------------------------------------------------------------

function mStat_OpeningFcn(hObject, eventdata, handles, varargin)
%      This function executes just before mStat is made 
%      visible.  This function has no output arguments (see OutputFcn), 
%      however, the following input arguments apply.  
addpath utils
handles.output = hObject;
handles.mStat_version='v1.1';
% Set the name and version
set(handles.figure1,'Name',['Meander Statistics Toolbox (MStaT) ' handles.mStat_version], ...
    'DockControls','off')

set_enable(handles,'init')

%%%%%%%%%
%scalebar
%%%%%%%%%

% Push messages to Log Window:
    % ----------------------------
    log_text = {...
        '';...
        ['%----------- ' datestr(now) ' ------------%'];...
        'LETs START!!!'};
    statusLogging(handles.LogWindow, log_text)
handles.start=1;
guidata(hObject, handles);%      Updates handles structure.

%--------------------------------------------------------------------------

function varargout = mStat_OutputFcn(hObject, eventdata, handles)
%      Output arguments from this function are returned to the command line. 
%      Input arguments from this function are defined as below.  
%
varargout{1} = handles.output;

% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
pos = get(handles.mStatBackground,'position');
 axes(handles.mStatBackground);
% if ~isdeployed 
   X = imread('MStaT_background.png');
   imdisp(X,'size',[pos(4) pos(3)]) % Avoids problems with users not having Image Processing TB

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% Hint: delete(hObject) closes the figure
who_called = get(hObject,'tag');
close_button = questdlg(...
    'You are about to exit MStaT. Any unsaved work will be lost. Are you sure?',...
    'Exit MStaT?','No');
switch close_button
    case 'Yes'
        delete(hObject)
        close all hidden
    otherwise
        return
end

%--------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%
%MENU PANEL
%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
function file_Callback(hObject, eventdata, handles)
%Empty

% -------------------------------------------------------------------------
function newproject_Callback(hObject, eventdata, handles)
%New project function
axes(handles.pictureReach)
cla(handles.pictureReach,'reset')
set(gca,'xtick',[])
set(gca,'ytick',[])
clear geovar
clc

% Push messages to Log Window:
% ----------------------------
log_text = {...
            '';...
            ['%--- ' datestr(now) ' ---%'];...
            'NEW PROJECT!'};
            statusLogging(handles.LogWindow, log_text)
                
set_enable(handles,'init')


% -------------------------------------------------------------------------
function openfunction_Callback(hObject, eventdata, handles)
%open function
set_enable(handles,'init')

handles.Module = 1;

%This function incorporate the initial data input
handles.multisel='on';
handles.first=1;
guidata(hObject,handles)

mStat_ReadInputFiles(handles);


% --------------------------------------------------------------------
function singlefile_Callback(hObject, eventdata, handles)
%empty

% --------------------------------------------------------------------
function multifiles_Callback(hObject, eventdata, handles)
%empty

% --------------------------------------------------------------------
function close_Callback(hObject, eventdata, handles)
close

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Export function

% --------------------------------------------------------------------
function exportfunction_Callback(hObject, eventdata, handles)
%Empty

%Matlab Export
% --------------------------------------------------------------------
function exportmat_Callback(hObject, eventdata, handles)
saveDataCallback(hObject, eventdata, handles)
            

function saveDataCallback(hObject, eventdata, handles)

[fileMAT,pathMAT] = uiputfile('*.mat','Save .mat file');

if fileMAT==0
else
    str=['Exporting' fileMAT];
    hwait = waitbar(0,str,'Name','MStaT');
    Parameters.PathFileName  = fullfile(pathMAT,fileMAT); 
    Parameters.geovar = getappdata(0,'geovar');
    waitbar(0.5,hwait)

    save([pathMAT fileMAT], 'Parameters');
    waitbar(1,hwait)
    delete(hwait)
    
    % Push messages to Log Window:
    % ----------------------------
    log_text = {...
            '';...
            ['%--- ' datestr(now) ' ---%'];...
            'Export .mat File Succesfully!'};
            statusLogging(handles.LogWindow, log_text)
end

%Excel Export
% --------------------------------------------------------------------
function exportexcelfile_Callback(hObject, eventdata, handles)
savexlsDataCallback(hObject, eventdata, handles)

% Push messages to Log Window:
% ----------------------------
log_text = {...
            '';...
            ['%--- ' datestr(now) ' ---%'];...
            'Export .xlsx File succesfully!'};
            statusLogging(handles.LogWindow, log_text)
            
            
function savexlsDataCallback(hObject, eventdata, handles)
%Read data
geovar = getappdata(0,'geovar');

close_button = questdlg(...
    'Do you like export all channel analyzed?', 'MStaT: Export Excel Data',...
    'All Data','Only Selected');
switch close_button
    case 'All Data'
        for i=1:length(geovar)
            mStat_ExportExcel(geovar{i})
        end
    case 'Only Selected'
        mStat_ExportExcel(geovar{handles.ChannelSel})
end

%Google Export
% --------------------------------------------------------------------
function exportkmlfile_Callback(hObject, eventdata, handles)
geovar = getappdata(0,'geovar');
ReadVar = getappdata(0,'ReadVar');

%This function esport the kmzfile for Google Earth
[file,path] = uiputfile('*.kml','Save .kml File');

if file==0
else
    str=['Exporting' file];
    hwait = waitbar(0,str,'Name','MStaT');
    namekml=(fullfile(path,file));

    % 3 file export function
    %first
    [xcoord,ycoord]=utm2deg(ReadVar{handles.ChannelSel}.xCoord,...
        ReadVar{handles.ChannelSel}.yCoord,char(ReadVar{handles.ChannelSel}.utmzone(:,1:4)));
    latlon1=[xcoord ycoord];

    %second
    for i=1:length(geovar{handles.ChannelSel}.xValleyCenter)
        utmzoneva(i,1)=cellstr(ReadVar{handles.ChannelSel}.utmzone(1,1:4));
    end
    utmva=char(utmzoneva);
    waitbar(0.5,hwait)
    
    [xvalley,yvalley]=utm2deg(geovar{handles.ChannelSel}.xValleyCenter,...
        geovar{handles.ChannelSel}.yValleyCenter,char(utmzoneva));
    latlon2=[xvalley yvalley];

    %third
    for i=1:length(geovar{handles.ChannelSel}.inflectionX)
        utmzoneinf(i,1)=cellstr(ReadVar{handles.ChannelSel}.utmzone(1,1:4));
    end

    [xinflectionY,yinflectionY]=utm2deg(geovar{handles.ChannelSel}.inflectionX,...
        geovar{handles.ChannelSel}.inflectionY,char(utmzoneinf));
    latlon3=[xinflectionY yinflectionY];

    % Write latitude and longitude into a KML file
    mStat_ExportKml(namekml,latlon1,latlon2,latlon3);
    
    waitbar(1,hwait)
    delete(hwait)
    
    % Push messages to Log Window:
    % ----------------------------
    log_text = {...
                '';...
                ['%--- ' datestr(now) ' ---%'];...
                'Export .kml File succesfully!'};
                statusLogging(handles.LogWindow, log_text)

end


%Export Figures    
% --------------------------------------------------------------------
function exportfiguregraphics_Callback(hObject, eventdata, handles)
%export figure function
[file,path] = uiputfile('*.tif','Save .tif File');

if file==0
else
    F = getframe(handles.pictureReach);
    Image = frame2im(F);
    imwrite(Image, fullfile(path,file),'Resolution',[1080,960])

    % Push messages to Log Window:
    % ----------------------------
    log_text = {...
                '';...
                ['%--- ' datestr(now) ' ---%'];...
                'Export .tif File succesfully!'};
                statusLogging(handles.LogWindow, log_text)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%
%Tools
%%%%%%%%%%
% --------------------------------------------------------------------
function tools_Callback(hObject, eventdata, handles)
% Empty

% --------------------------------------------------------------------
function evaldecomp_Callback(hObject, eventdata, handles)
% Empty

% --------------------------------------------------------------------
function waveletanalysis_Callback(hObject, eventdata, handles)
%Wavelet analysis
geovar=getappdata(0,'geovar');
handles.getWaveStats = mStat_WaveletAnalysis(geovar{handles.ChannelSel});


% --------------------------------------------------------------------
function riverstatistics_Callback(hObject, eventdata, handles)
% This function executes when the user presses the getRiverStats button
% and requires the following input arguments.
geovar=getappdata(0,'geovar');
handles.getRiverStats = mStat_StatisticsVariables(geovar{handles.ChannelSel});


% --------------------------------------------------------------------
function backgroundimage_Callback(hObject, eventdata, handles)
% Add backgroud image
[handles.FileImage,handles.PathImage] = uigetfile({'*.tif';'*.*'},'Select Graphic File');
guidata(hObject,handles)

if handles.FileImage==0
else
    
    axes(handles.pictureReach);
    hold on;
    mapshow(fullfile(handles.PathImage,handles.FileImage))
    hold on;

    geovar=getappdata(0, 'geovar');
    sel=get(handles.selector,'Value')-1;%Decomposition method
    
    %Begin plot
     mStat_plotplanar(geovar{handles.ChannelSel}.equallySpacedX, geovar{handles.ChannelSel}.equallySpacedY,...
         geovar{handles.ChannelSel}.inflectionPts, geovar{handles.ChannelSel}.x0,...
         geovar{handles.ChannelSel}.y0, geovar{handles.ChannelSel}.x_sim,...
     geovar{handles.ChannelSel}.newMaxCurvX, geovar{handles.ChannelSel}.newMaxCurvY,...
     handles.pictureReach,sel);
 
     % Push messages to Log Window:
    % ----------------------------
    log_text = {...
                '';...
                ['%--- ' datestr(now) ' ---%'];...
                'Background Image read succesfully!'};
                statusLogging(handles.LogWindow, log_text)

        
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%
%Modules
%%%%%%%%%%

% --------------------------------------------------------------------
function modules_Callback(hObject, eventdata, handles)
% Empty

% --------------------------------------------------------------------

% --------------------------------------------------------------------
function migrationanalyzer_Callback(hObject, eventdata, handles)
%Migration Analyzer Tool
mStat_MigrationAnalyzer;


% --------------------------------------------------------------------
function confluencesanalyzer_Callback(hObject, eventdata, handles)
%Confluences and Bifurcation Tools
mStat_ConfluencesAnalyzer;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%
%Settings
%%%%%%%%%%%%%%
% --------------------------------------------------------------------
function setti_Callback(hObject, eventdata, handles)
% Empty


% --------------------------------------------------------------------
% function unitsfunction_Callback(hObject, eventdata, handles)
% % Empty
% 
% 
% % --------------------------------------------------------------------
% function metricunits_Callback(hObject, eventdata, handles)
% % Metric factor function
% if handles.start==0
%     munits=1/0.3048;
% else
%     munits=1;
% end
% handles.geovar.lengthCurved=handles.geovar.lengthCurved*munits;
% handles.geovar.wavelengthOfBends=handles.geovar.wavelengthOfBends*munits;
% handles.geovar.amplitudeOfBends=handles.geovar.amplitudeOfBends*munits;
% handles.geovar.downstreamSlength=handles.geovar.downstreamSlength*munits;
% handles.geovar.upstreamSlength=handles.geovar.upstreamSlength*munits;
% handles.width=handles.width*munits;
% guidata(hObject,handles)
% 
% set(handles.widthinput,'String',handles.width)
% 
% % Retrieve the selected bend ID number from the "bendSelect" listbox.
% selectedBend = get(handles.bendSelect,'Value');
% 
% % -------------------------------------------------------------------------
% 
% % Assign the bend statistics to an output array.
% matrixOfBendStatistics = [handles.geovar.sinuosityOfBends(selectedBend),...
%     handles.geovar.lengthStraight(selectedBend),handles.geovar.lengthCurved(selectedBend),...
%     handles.geovar.wavelengthOfBends(selectedBend), handles.geovar.amplitudeOfBends(selectedBend),...
%     handles.geovar.downstreamSlength(selectedBend),handles.geovar.upstreamSlength(selectedBend)];
% 
% matrixOfBendStatistics = matrixOfBendStatistics';
% 
% % Setappdata is a function which allows the matrix of bend statistics
% % to be accessed by multiple GUI windows.  
% setappdata(0, 'matrixOfBendStatistics', matrixOfBendStatistics);
% guidata(hObject, handles);
% 
% % Set the statistics to the "IndividualStats" table in 
% % the main GUI.  
% set(handles.sinuosity, 'String', round(handles.geovar.sinuosityOfBends(selectedBend),2));
% set(handles.curvaturel, 'String', round(handles.geovar.lengthCurved(selectedBend),2));
% set(handles.wavel, 'String', round(handles.geovar.wavelengthOfBends(selectedBend),2));
% set(handles.amplitude, 'String', round(handles.geovar.amplitudeOfBends(selectedBend),2));
% set(handles.dstreamL, 'String', round(handles.geovar.downstreamSlength(selectedBend),2));
% set(handles.ustreamL, 'String', round(handles.geovar.upstreamSlength(selectedBend),2));
% handles.munits=1;
% guidata(hObject, handles);
% 
% 
% % --------------------------------------------------------------------
% function englishunits_Callback(hObject, eventdata, handles)
% % English units
% 
% eunits=0.3048;
% 
% handles.geovar.lengthCurved=handles.geovar.lengthCurved*eunits;
% handles.geovar.wavelengthOfBends=handles.geovar.wavelengthOfBends*eunits;
% handles.geovar.amplitudeOfBends=handles.geovar.amplitudeOfBends*eunits;
% handles.geovar.downstreamSlength=handles.geovar.downstreamSlength*eunits;
% handles.geovar.upstreamSlength=handles.geovar.upstreamSlength*eunits;
% handles.width=handles.width*eunits;
% guidata(hObject,handles)
% 
% set(handles.widthinput,'String',handles.width)
% 
% % Retrieve the selected bend ID number from the "bendSelect" listbox.
% selectedBend = get(handles.bendSelect,'Value');
% 
% % -------------------------------------------------------------------------
% 
% % Assign the bend statistics to an output array.
% matrixOfBendStatistics = [handles.geovar.sinuosityOfBends(selectedBend),...
%     handles.geovar.lengthStraight(selectedBend),handles.geovar.lengthCurved(selectedBend),...
%     handles.geovar.wavelengthOfBends(selectedBend), handles.geovar.amplitudeOfBends(selectedBend),...
%     handles.geovar.downstreamSlength(selectedBend),handles.geovar.upstreamSlength(selectedBend)];
% 
% matrixOfBendStatistics = matrixOfBendStatistics';
% 
% % Setappdata is a function which allows the matrix of bend statistics
% % to be accessed by multiple GUI windows.  
% setappdata(0, 'matrixOfBendStatistics', matrixOfBendStatistics);
% guidata(hObject, handles);
% 
% % Set the statistics to the "IndividualStats" table in 
% % the main GUI.  
% set(handles.sinuosity, 'String', round(handles.geovar.sinuosityOfBends(selectedBend),2));
% set(handles.curvaturel, 'String', round(handles.geovar.lengthCurved(selectedBend),2));
% set(handles.wavel, 'String', round(handles.geovar.wavelengthOfBends(selectedBend),2));
% set(handles.amplitude, 'String', round(handles.geovar.amplitudeOfBends(selectedBend),2));
% set(handles.dstreamL, 'String',round(handles.geovar.downstreamSlength(selectedBend),2));
% set(handles.ustreamL, 'String', round(handles.geovar.upstreamSlength(selectedBend),2));
% handles.eunits=0.3048;
% guidata(hObject, handles);
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Help
% --------------------------------------------------------------------
function helpfunction_Callback(hObject, eventdata, handles)
% Empty


% --------------------------------------------------------------------
function usersguide_Callback(hObject, eventdata, handles)
%Send to web page with code modufy to github
try
    web('https://meanderstatistics.blogspot.com/p/tutorials.html')
catch err %#ok<NASGU>
	if isdeployed
        errLogFileName = fullfile(pwd,...
            ['errorLog' datestr(now,'yyyymmddHHMMSS') '.txt']);
        msgbox({['An unexpected error occurred. Error code: ' err.identifier];...
            ['Error details are being written to the following file: '];...
            errLogFileName},...
            'MStaT Status: Unexpected Error',...
            'error');
        fid = fopen(errLogFileName,'W');
        fwrite(fid,err.getReport('extended','hyperlinks','off'));
        fclose(fid);
        rethrow(err)
    else
        msgbox(['An unexpected error occurred. Error code: ' err.identifier],...
            'MStaT Status: Unexpected Error',...
            'error');
        rethrow(err);
    end
end


% --------------------------------------------------------------------
function checkforupdates_Callback(hObject, eventdata, handles)
%Send to web page for updates
try
    web('https://meanderstatistics.blogspot.com/p/download.html')
catch err %#ok<NASGU>
	if isdeployed
        errLogFileName = fullfile(pwd,...
            ['errorLog' datestr(now,'yyyymmddHHMMSS') '.txt']);
        msgbox({['An unexpected error occurred. Error code: ' err.identifier];...
            ['Error details are being written to the following file: '];...
            errLogFileName},...
            'MStaT Status: Unexpected Error',...
            'error');
        fid = fopen(errLogFileName,'W');
        fwrite(fid,err.getReport('extended','hyperlinks','off'));
        fclose(fid);
        rethrow(err)
    else
        msgbox(['An unexpected error occurred. Error code: ' err.identifier],...
            'MStaT Status: Unexpected Error',...
            'error');
        rethrow(err);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%
%MENU TOOLBAR
%%%%%%%%%%%%%%%%%%

% --------------------------------------------------------------------
function zoomextendedT_ClickedCallback(hObject, eventdata, handles)
geovar=getappdata(0, 'geovar');
sel=get(handles.selector,'Value')-1;%Decomposition method
%Begin plot
axes(handles.pictureReach)
cla(handles.pictureReach)
 mStat_plotplanar(geovar{handles.ChannelSel}.equallySpacedX, geovar{handles.ChannelSel}.equallySpacedY,...
     geovar{handles.ChannelSel}.inflectionPts, geovar{handles.ChannelSel}.x0,...
     geovar{handles.ChannelSel}.y0, geovar{handles.ChannelSel}.x_sim,...
 geovar{handles.ChannelSel}.newMaxCurvX, geovar{handles.ChannelSel}.newMaxCurvY,...
 handles.pictureReach,sel);


% --------------------------------------------------------------------
function panT_OnCallback(hObject, eventdata, handles)
axes(handles.pictureReach)
scalebar OFF


% --------------------------------------------------------------------
function panT_OffCallback(hObject, eventdata, handles)
axes(handles.pictureReach)
scalebar 


% --------------------------------------------------------------------
function panT_ClickedCallback(hObject, eventdata, handles)
pan


% --------------------------------------------------------------------
function rulerT_ClickedCallback(hObject, eventdata, handles) 
%empty

% --------------------------------------------------------------------
function newprojectT_ClickedCallback(hObject, eventdata, handles)
newproject_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function savematfileT_ClickedCallback(hObject, eventdata, handles)
exportmat_Callback(hObject, eventdata, handles)


% --------------------------------------------------------------------
function openT_ClickedCallback(hObject, eventdata, handles)
openfunction_Callback(hObject, eventdata, handles)


% --------------------------------------------------------------------
function rulerT_OnCallback(hObject, eventdata, handles)
axes(handles.pictureReach)
%imdistline(hparent)

 axis manual
 handles.Figruler = imline(gca);
 % Get original position
 pos = getPosition(handles.Figruler);
 % Get updated position as the ruler is moved around
 id = addNewPositionCallback(handles.Figruler,@(pos) title(mat2str(pos,3)));
 
 x=pos(:,1);
 y=pos(:,2);
 
 handles.ruler=imdistline(handles.pictureReach,x,y);
 guidata(hObject,handles)


% --------------------------------------------------------------------
function rulerT_OffCallback(hObject, eventdata, handles)
delete(handles.ruler)
delete(handles.Figruler)


% --------------------------------------------------------------------
function datacursorT_OnCallback(hObject, eventdata, handles)
axes(handles.pictureReach); 

%data cursor type
dcm_obj = datacursormode(gcf);

set(dcm_obj,'UpdateFcn',@mStat_myupdatefcn);

set(dcm_obj,'Displaystyle','Window','Enable','on');
pos = get(0,'userdata');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%
%Initial Panel
%%%%%%%%%%%%%%%%%%%


% --- Executes during object creation, after setting all properties.
function popupChannel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on popupChannel and none of its controls.
function popupChannel_KeyPressFcn(hObject, eventdata, handles)
%empty


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over popupChannel.
function popupChannel_ButtonDownFcn(hObject, eventdata, handles)
%empty


% --- Executes on button press in advancedsetting.
function advancedsetting_Callback(hObject, eventdata, handles)

mStat_AdvancedSetting(handles.ChannelSel)


% --- Executes on button press in recalculate.
function recalculate_Callback(hObject, eventdata, handles)
%Recalculate using a New Width 

% clear figures and data 
axes(handles.pictureReach)
cla(handles.pictureReach)
clear selectBend
clc
guidata(hObject,handles)

mStat_Calculate(handles)
set_enable(handles,'results')


% --- Executes on selection change in popupChannel.
function popupChannel_Callback(hObject, eventdata, handles)

handles.ChannelSel=get(handles.popupChannel,'Value')-1;
guidata(hObject, handles);
sel=get(handles.selector,'Value')-1;%Decomposition method

geovar=getappdata(0, 'geovar');

if handles.ChannelSel==0
   % set_enable(handles,'init')
else
    
    set_enable(handles,'loadfiles')
    % %put the bend on the table
    bendListStr = geovar{handles.ChannelSel}.bendID1';
    set (handles.bendSelect, 'string', bendListStr);
    
%       Write the width
     %set(handles.widthinput, 'String', ReadVar{handles.ChannelSel}.width,'Enable','on');

    %      Retrieve the selected bend ID number from the "bendSelect" listbox.
    selectedBend = get(handles.bendSelect,'Value');
    handles.selectedBend = num2str(selectedBend);

    %       setappdata is a function which allows the selected bend
    %       to be accessed by multiple GUI windows.  
    setappdata(0, 'selectedBend', handles.selectedBend);
    guidata(hObject, handles);

    %     Start by retreiving the selected bend given the user input from the
    %     "bendSelect" listbox. 
    handles.selectedBend = getappdata(0, 'selectedBend');
    handles.selectedBend = str2double(handles.selectedBend);
    guidata(hObject, handles); 
    
    %Begin plot
    axes(handles.pictureReach)
    cla(handles.pictureReach)
     mStat_plotplanar(geovar{handles.ChannelSel}.equallySpacedX, geovar{handles.ChannelSel}.equallySpacedY,...
         geovar{handles.ChannelSel}.inflectionPts, geovar{handles.ChannelSel}.x0,...
         geovar{handles.ChannelSel}.y0, geovar{handles.ChannelSel}.x_sim,...
     geovar{handles.ChannelSel}.newMaxCurvX, geovar{handles.ChannelSel}.newMaxCurvY,...
     handles.pictureReach,sel);


%    enable results
   set_enable(handles,'results')
    
% Push messages to Log Window:
% ----------------------------
log_text = {...
            '';...
            ['%--- ' datestr(now) ' ---%'];...
            'MStaT Summary';...
            'Width [m]:';[cell2mat({geovar{handles.ChannelSel}.width(end,1)})];...
            'Total Length Analyzed [km]:';[round(cell2mat({geovar{handles.ChannelSel}.intS(end,1)/1000}),2)];...
            'Bends Found:';[cell2mat({geovar{handles.ChannelSel}.nBends})];...
            'Mean Sinuosity:';[round(cell2mat({nanmean(geovar{handles.ChannelSel}.sinuosityOfBends)}),2)];...
            'Mean Amplitude [m]:';[round(cell2mat({nanmean(geovar{handles.ChannelSel}.amplitudeOfBends)}),2)];...
            'Mean Arc-Wavelength [m]:';[round(cell2mat({nanmean(geovar{handles.ChannelSel}.lengthCurved)}),2)];...
            'Mean Wavelength [m]:';[round(cell2mat({nanmean(geovar{handles.ChannelSel}.wavelengthOfBends)}),2)]};
            statusLogging(handles.LogWindow, log_text)
end


% --------------------------------------------------------------------
function bendstatistics_Callback(hObject, eventdata, handles)
% empty


% --- Executes on button press in selectData.
function selectData_Callback(hObject, eventdata, handles)
%Empty


function bendSelect_Callback(hObject, eventdata, handles)
% This function executes when the user presses the Get Bend Statistics 
% button and requires the following input arguments.  

geovar=getappdata(0, 'geovar');

%cla(handles.pictureReach)
guidata(hObject,handles)

% Retrieve the selected bend ID number from the "bendSelect" listbox.
selectedBend = get(handles.bendSelect,'Value');

% setappdata is a function which allows the handles.Channeled bend
% to be accessed by multiple GUI windows.  
setappdata(0, 'selectedBend', handles.selectedBend);
guidata(hObject, handles);

% Start by retreiving the selected bend given the user input from the
% "bendSelect" listbox. 
handles.selectedBend = getappdata(0, 'selectedBend');
handles.selectedBend = str2double(handles.selectedBend);
guidata(hObject, handles);

% -------------------------------------------------------------------------

% Assign the bend statistics to an output array.
matrixOfBendStatistics = [geovar{handles.ChannelSel}.sinuosityOfBends(selectedBend),...
    geovar{handles.ChannelSel}.lengthStraight(selectedBend),geovar{handles.ChannelSel}.lengthCurved(selectedBend),...
    geovar{handles.ChannelSel}.wavelengthOfBends(selectedBend), geovar{handles.ChannelSel}.amplitudeOfBends(selectedBend),...
    geovar{handles.ChannelSel}.downstreamSlength(selectedBend),geovar{handles.ChannelSel}.upstreamSlength(selectedBend)];

matrixOfBendStatistics = matrixOfBendStatistics';

% Setappdata is a function which allows the matrix of bend statistics
% to be accessed by multiple GUI windows.  
setappdata(0, 'matrixOfBendStatistics', matrixOfBendStatistics);
guidata(hObject, handles);

% Set the statistics to the "IndividualStats" table in 
% the main GUI.  
set(handles.sinuosity, 'String', round(geovar{handles.ChannelSel}.sinuosityOfBends(selectedBend),2));
set(handles.curvaturel, 'String', round(geovar{handles.ChannelSel}.lengthCurved(selectedBend),2));
set(handles.wavel, 'String', round(geovar{handles.ChannelSel}.wavelengthOfBends(selectedBend),2));
set(handles.amplitude, 'String', round(geovar{handles.ChannelSel}.amplitudeOfBends(selectedBend),2));
set(handles.dstreamL, 'String',round(geovar{handles.ChannelSel}.downstreamSlength(selectedBend),2));
set(handles.ustreamL, 'String', round(geovar{handles.ChannelSel}.upstreamSlength(selectedBend),2));
set(handles.condition, 'String', geovar{handles.ChannelSel}.condition(selectedBend));
guidata(hObject, handles);
    
uiresume(gcbf);
%--------------------------------------------------------------------------
 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Panel Selection
% --- Executes during object creation, after setting all properties.
function uipanelselect_CreateFcn(hObject, eventdata, handles)
%Empty


function bendSelect_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%--------------------------------------------------------------------------


function selectData_CreateFcn(hObject, eventdata, handles)
set(hObject,'enable','off')


% --- Executes on selection change in selector.
function selector_Callback(hObject, eventdata, handles)
%This function select the bend and shows the parameters results
axes(handles.pictureReach)
cla(handles.pictureReach)
guidata(hObject,handles)

mStat_Calculate(handles)


% --- Executes during object creation, after setting all properties.
function selector_CreateFcn(hObject, eventdata, handles)

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%--------------------------------------------------------------------------
% --- Executes on button press in gobend.
function gobend_Callback(hObject, eventdata, handles)
%This function go to bend selected and replot the picture
geovar=getappdata(0, 'geovar');

sel=get(handles.selector,'Value')-1;%Decomposition method

cla(handles.pictureReach)
mStat_plotplanar(geovar{handles.ChannelSel}.equallySpacedX, geovar{handles.ChannelSel}.equallySpacedY,...
    geovar{handles.ChannelSel}.inflectionPts,geovar{handles.ChannelSel}.x0,...
    geovar{handles.ChannelSel}.y0, geovar{handles.ChannelSel}.x_sim,...
    geovar{handles.ChannelSel}.newMaxCurvX, geovar{handles.ChannelSel}.newMaxCurvY, ...
    handles.pictureReach,sel);

zoom out

selectedBend = get(handles.bendSelect,'Value');

 if geovar{handles.ChannelSel}.amplitudeOfBends(selectedBend)~=0 | isfinite(geovar{handles.ChannelSel}.upstreamSlength)
    %      selectdata text labels for all bends.    
    axes(handles.pictureReach); 
    set(gca, 'Color', 'w')
    %axis normal; 
    loc = find(geovar{handles.ChannelSel}.newMaxCurvS == geovar{handles.ChannelSel}.bend(selectedBend,2));
    zoom out
    zoomcenter(geovar{handles.ChannelSel}.newMaxCurvX(loc),geovar{handles.ChannelSel}.newMaxCurvY(loc),2)
 else 
 end

% Call the "userSelectBend" function to get the index of intersection
% points and the highlighted bend limits.  
[handles.highlightX, handles.highlightY, ~] = userSelectBend(geovar{handles.ChannelSel}.intS, selectedBend,...
    geovar{handles.ChannelSel}.equallySpacedX,geovar{handles.ChannelSel}.equallySpacedY,...
    geovar{handles.ChannelSel}.newInflectionPts,geovar{handles.ChannelSel}.sResample);

 axes(handles.pictureReach);
% hold on
handles.highlightPlot = line(handles.highlightX(1,:), handles.highlightY(1,:), 'color', 'y', 'LineWidth',8); 

guidata(hObject,handles)
%--------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Planar Parameters Display
function sinuosity_Callback(hObject, eventdata, handles)
%Empty

% --- Executes during object creation, after setting all properties.
function sinuosity_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function curvaturel_Callback(hObject, eventdata, handles)
%Empty


% --- Executes during object creation, after setting all properties.
function curvaturel_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function wavel_Callback(hObject, eventdata, handles)
% Empty


% --- Executes during object creation, after setting all properties.
function wavel_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function amplitude_Callback(hObject, eventdata, handles)
% Empty


% --- Executes during object creation, after setting all properties.
function amplitude_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Extra Functions

% --- Executes during object creation, after setting all properties.
function condition_CreateFcn(hObject, eventdata, handles)
% Empty


% --- Executes on mouse motion over figure - except title and menu.
function figure1_WindowButtonMotionFcn(hObject, eventdata, handles)
%Empty


% --- Executes during object creation, after setting all properties.
function IndividualStats_CreateFcn(hObject, eventdata, handles)
% Empty 


% --- Executes on button press in withinflectionpoints.
function withinflectionpoints_Callback(hObject, eventdata, handles)
% Empty


% --- Executes on button press in withvalleyline.
function withvalleyline_Callback(hObject, eventdata, handles)
% Empty


% --- Executes during object creation, after setting all properties.
function mStatBackground_CreateFcn(hObject, eventdata, handles)
%empty


% --- Executes on mouse press over axes background.
function pictureReach_ButtonDownFcn(hObject, eventdata, handles)
pan(handles.pictureReach)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%
%Extra function
%%%%%%%%%%%%%%%%%%%%

function set_enable(handles,enable_state)
Readvar = getappdata(0,'Readvar');

switch enable_state
    case 'init'
        set(handles.sinuosity,'String','','Enable','off')
        set(handles.curvaturel,'String','','Enable','off')
        set(handles.wavel,'String','','Enable','off')
        set(handles.amplitude,'String','','Enable','off')
        set(handles.ustreamL,'String','','Enable','off')
        set(handles.dstreamL,'String','','Enable','off')
        set(handles.condition,'String','','Enable','off')
        set(handles.bendSelect,'Visible','off','String','','Enable','off')
        set(handles.exportfunction,'Enable','off')
        set(handles.exportkmlfile,'Enable','off')
        %set(handles.setti,'Enable','off')  
        set(handles.gobend,'Enable','off')   
        set(handles.selector,'Enable','off','Value',1)  
        set(handles.bendSelect,'Enable','off') 
        set(handles.waveletanalysis,'Enable','off')
        set(handles.riverstatistics,'Enable','off')
        set(handles.backgroundimage,'Enable','off')
        set(handles.savematfileT,'Enable','off')
        set(handles.rulerT,'Enable','off')
        set(handles.zoomextendedT,'Enable','off')
        set(handles.zoominT,'Enable','off')
        set(handles.zoomoutT,'Enable','off')
        set(handles.channelname,'Enable','off')
        set(handles.panT,'Enable','off')
        set(handles.datacursorT,'Enable','off')
        set(handles.popupChannel,'String','Select Channel','Enable','off','Value',1)
        axes(handles.pictureReach)
        cla(handles.pictureReach)
        clear selectBend
        clc
    case 'loadfiles'
        set(handles.sinuosity,'Enable','on')
        set(handles.curvaturel,'Enable','on')
        set(handles.wavel,'Enable','on')
        set(handles.amplitude,'Enable','on')
        set(handles.ustreamL,'Enable','on')
        set(handles.dstreamL,'Enable','on')
        set(handles.channelname,'Enable','on')
        set(handles.bendSelect,'Visible','on','String','','Enable','on')
        set(handles.condition,'String','','Enable','on')
       % set(handles.setti,'Enable','on')
        set(handles.gobend,'Enable','on')
        set(handles.selector,'Enable','on')  
        set(handles.bendSelect,'Enable','on')  
        set(handles.popupChannel,'Enable','on')
        set(handles.savematfileT,'Enable','on')
        set(handles.rulerT,'Enable','on')
        set(handles.zoomextendedT,'Enable','on')
        set(handles.zoominT,'Enable','on')
        set(handles.zoomoutT,'Enable','on')
        set(handles.panT,'Enable','on')
        set(handles.datacursorT,'Enable','on')
    case 'results'
        set(handles.waveletanalysis,'Enable','on')  
        set(handles.riverstatistics,'Enable','on')  
        set(handles.exportfunction,'Enable','on')
        handles.start=0;
        set(handles.backgroundimage,'Enable','on')
    otherwise                
end
       

% --------------------------------------------------------------------
function pictureReach_CreateFcn(hObject, eventdata, handles)
%Empty


% --------------------------------------------------------------------
function pictureReach_DeleteFcn(hObject, eventdata, handles)
%Empty


% % --------------------------------------------------------------------
function Opengui_ClickedCallback(hObject, eventdata, handles)
openfile_Callback(hObject, eventdata, handles)


% --- Executes on selection change in LogWindow.
function LogWindow_Callback(hObject, eventdata, handles)
% empty


% --- Executes during object creation, after setting all properties.
function LogWindow_CreateFcn(hObject, eventdata, handles)

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function mStat_Calculate(handles)

ReadVar=getappdata(0, 'ReadVar');
geovar=getappdata(0, 'geovar');
AdvancedSet=getappdata(0, 'AdvancedSet');

%Read selector
sel=get(handles.selector,'Value')-1;%Decomposition method
    
%Function of calculate
%Calculate and plot planar variables
if sel==0
else
    [geovar{handles.ChannelSel}]=mStat_planar(ReadVar{handles.ChannelSel}.xCoord,ReadVar{handles.ChannelSel}.yCoord,...
        ReadVar{handles.ChannelSel}.width,ReadVar{handles.ChannelSel}.File,...
        sel,handles.Module,ReadVar{handles.ChannelSel}.Level,AdvancedSet{handles.ChannelSel});

    %Begin plot
         mStat_plotplanar(geovar{handles.ChannelSel}.equallySpacedX, geovar{handles.ChannelSel}.equallySpacedY,...
             geovar{handles.ChannelSel}.inflectionPts, geovar{handles.ChannelSel}.x0,...
             geovar{handles.ChannelSel}.y0, geovar{handles.ChannelSel}.x_sim,...
         geovar{handles.ChannelSel}.newMaxCurvX, geovar{handles.ChannelSel}.newMaxCurvY,...
         handles.pictureReach,sel);

    %Store data file
    setappdata(0, 'geovar', geovar);

    %update listt
    bendListStr = geovar{handles.ChannelSel}.bendID1';
    set (handles.bendSelect, 'string', bendListStr);

    % Push messages to Log Window:
    % ----------------------------
    log_text = {...
                '';...
                ['%--- ' datestr(now) ' ---%'];...
                'MStaT Summary';...
                'Width [m]:';[cell2mat({geovar{handles.ChannelSel}.width(end,1)})];...
                'Total Length Analyzed [km]:';[round(cell2mat({geovar{handles.ChannelSel}.intS(end,1)/1000}),2)];...
                'Bends Found:';[cell2mat({geovar{handles.ChannelSel}.nBends})];...
                'Mean Sinuosity:';[round(cell2mat({nanmean(geovar{handles.ChannelSel}.sinuosityOfBends)}),2)];...
                'Mean Amplitude [m]:';[round(cell2mat({nanmean(geovar{handles.ChannelSel}.amplitudeOfBends)}),2)];...
                'Mean Arc-Wavelength [m]:';[round(cell2mat({nanmean(geovar{handles.ChannelSel}.lengthCurved)}),2)];...
                'Mean Wavelength [m]:';[round(cell2mat({nanmean(geovar{handles.ChannelSel}.wavelengthOfBends)}),2)]};
                statusLogging(handles.LogWindow, log_text)
end
                    

function channelname_Callback(hObject, eventdata, handles)
% empty

% --- Executes during object creation, after setting all properties.
function channelname_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channelname (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function export_txt_average_values_Callback(hObject, eventdata, handles)
% hObject    handle to export_txt_average_values (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
geovar=getappdata(0, 'geovar');
handles.ChannelSel=get(handles.popupChannel,'Value')-1;

if (handles.ChannelSel == 0)
    
else
   
   %Open save file window (only txt file format for now)
   [file,path] = uiputfile('*.txt', 'Export average metrics values', 'average_metrics_values');

   %get data from geovar and selected channel
   data = geovar{handles.ChannelSel};
   
   tableValues = [cell2mat({data.nBends}), cell2mat({round(nanmean(data.sinuosityOfBends),2)}), cell2mat({round(nanmean(data.lengthCurved),2)}), cell2mat({round(nanmean(data.wavelengthOfBends),2)}), cell2mat({round(nanmean(data.amplitudeOfBends),2)})];
   tableHeaders = ["numberBends", "Sinuosity", "Arc_Wavelength", "Wavelength", "Amplitude"];

   %uncomment to save values as variables to workspace
   %assignin('base','H',tableHeaders);
   %assignin('base','V',tableValues);
   
   %output file
   fid = fopen(strcat(path, file),'wt'); 
    
    for i = 1:5
        fprintf(fid,'%s',tableHeaders(1,i));
        fprintf(fid,'\t');
        fprintf(fid,'%.3f',tableValues(1,i));
        fprintf(fid,'\n');
    end

    fclose(fid);
    
end


% --------------------------------------------------------------------
function export_meancenterline_Callback(hObject, eventdata, handles)
% hObject    handle to export_meancenterline (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 
geovar=getappdata(0, 'geovar');
handles.ChannelSel=get(handles.popupChannel,'Value')-1;

if(handles.ChannelSel == 0)
    %No action
else
    
    %Open save file window (only shp file format for now)
    [file,path] = uiputfile('*.shp', 'Export mean centerline', 'mstat_mean_centerline.shp');
    
    %get data from geovar and selected channel
    data = geovar{handles.ChannelSel};
    
    %Create geovector with coordinates as vector (output file of type LINE)
    geoMeancenterline = geoshape(-imag(data.x_sim), real(data.x_sim));
    geoMeancenterline.Geometry = 'line';
    shapewrite(geoMeancenterline, strcat(path, file));
end


% --------------------------------------------------------------------
function export_bends_Callback(hObject, eventdata, handles)
% hObject    handle to export_bends (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

geovar=getappdata(0, 'geovar');
handles.ChannelSel=get(handles.popupChannel,'Value')-1;

if(handles.ChannelSel == 0)
    
else
    
    %get data from geovar and selected channel
    data = geovar{handles.ChannelSel};
    
    indexOfIntersectionPoints = zeros(1, length(data.intS));
    bend = cell(1, length(indexOfIntersectionPoints) + 1);
    
    for i = 1:length(data.intS)
    
        v = data.intS(i);
        [index, ~] = searchclosest(data.sResample, v);
     
        if isnan(index)
            
        else
            indexOfIntersectionPoints(i) = index; 
        end
     
    end
    
    for i = 1:length(indexOfIntersectionPoints)
    
        if (i == 1)

            bend{1} = [data.equallySpacedX(1:indexOfIntersectionPoints(i)) data.equallySpacedY(1:indexOfIntersectionPoints(i))];

        else

            bend{i} = [data.equallySpacedX(indexOfIntersectionPoints(i - 1):indexOfIntersectionPoints(i)) data.equallySpacedY(indexOfIntersectionPoints(i - 1):indexOfIntersectionPoints(i))];

        end

    end
    
    bend{length(indexOfIntersectionPoints) + 1} = [data.equallySpacedX(indexOfIntersectionPoints(end):end) data.equallySpacedY(indexOfIntersectionPoints(end):end)];

    %uncomment to save values as variables to workspace
    %assignin('base','bend',bend);

    hwait = waitbar(0,'Exporting bends...');

    %Open save file window (only shp file format for now)
    [file,path] = uiputfile('*.shp', 'Export bends information', 'mstat_bends.shp');

    waitbar(1/3, hwait);
    
    geoStruct = struct('ID', 0, 'Geometry', 0, 'Lat', 0, 'Lon', 0, 'Sinuosity', 0, 'Arc_Wavelength', 0, 'Amplitude', 0);
    geoStruct = repmat(geoStruct, length(bend), 1);
    
    %Populate Geostruct
    [geoStruct(1:length(bend)).Geometry]  = deal('Line');

    geoStruct(1).ID   = 1;
    geoStruct(1).Lat  = bend{1}(:,2);
    geoStruct(1).Lon  = bend{1}(:,1);
    geoStruct(1).Sinuosity          = 0.0;
    geoStruct(1).Arc_Wavelength     = 0.0;
    geoStruct(1).Amplitude          = 0.0;
    
    geoStruct(end).ID   = length(bend);
    geoStruct(end).Lat  = bend{end}(:,2);
    geoStruct(end).Lon  = bend{end}(:,1);
    geoStruct(end).Sinuosity          = 0.0;
    geoStruct(end).Arc_Wavelength     = 0.0;
    geoStruct(end).Amplitude          = 0.0;
    
    for i = 2:length(bend) - 1
        
        geoStruct(i).ID   = i;
        geoStruct(i).Lat  = bend{i}(:,2);
        geoStruct(i).Lon  = bend{i}(:,1);
        geoStruct(i).Sinuosity          = data.sinuosityOfBends(i-1);
        geoStruct(i).Arc_Wavelength     = data.lengthCurved(i-1);
        geoStruct(i).Amplitude          = data.amplitudeOfBends(i-1);
        
    end
    
    waitbar(2/3, hwait);
    
    %uncomment to save values as variables to workspace
    %assignin('base','geoStruct',geoStruct);
    
    shapewrite(geoStruct, strcat(path, file));
    
    waitbar(1, hwait);
    delete(hwait);
    
end


% --------------------------------------------------------------------
function export_inflection_points_Callback(hObject, eventdata, handles)
% hObject    handle to export_inflection_points (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


geovar=getappdata(0, 'geovar');
handles.ChannelSel=get(handles.popupChannel,'Value')-1;

if(handles.ChannelSel == 0)
    %No action
else
    
    %Open save file window (only shp file format for now)
    [file,path] = uiputfile('*.shp', 'Export inflection points', 'mstat_inflection_points.shp');

    %get data from geovar and selected channel
    data = geovar{handles.ChannelSel};
   
    hwait = waitbar(0,'Exporting inflection points...');
    
    %Create geovector with coordinates as vector (output file of type Point)
    Data = struct([]) ;  % initilaize structure 
    
    for i = 1:length(data.inflectionPts(:,1))
        Data(i).Geometry = 'Point'; 
        Data(i).Lat = data.inflectionPts(i,2);  % latitude 
        Data(i).Lon = data.inflectionPts(i,1);  % longitude 
        Data(i).Latitude = data.inflectionPts(i,2);  % latitude attribute
        Data(i).Longitude = data.inflectionPts(i,1);  % longitude attribute
        Data(i).ID  = i;  
    end
    
    shapewrite(Data, strcat(path, file));
    waitbar(1, hwait);
    delete(hwait);
    
end


% --------------------------------------------------------------------
function export_max_curvature_points_Callback(hObject, eventdata, handles)
% hObject    handle to export_max_curvature_points (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

geovar=getappdata(0, 'geovar');
handles.ChannelSel=get(handles.popupChannel,'Value')-1;

if(handles.ChannelSel == 0)
    %No action
else
    
    %Open save file window (only shp file format for now)
    [file,path] = uiputfile('*.shp', 'Save max curvature points', 'mstat_max_curvature_points.shp');

    %get data from geovar and selected channel
    data = geovar{handles.ChannelSel};
    
    hwait = waitbar(0,'Exporting max curvature points...');
    
    %Create geovector with coordinates as vector (output file of type Point)
    Data = struct([]) ;  % initilaize structure 
    
    for i = 1:length(data.newMaxCurvX)
        Data(i).Geometry = 'Point'; 
        Data(i).Lat = data.newMaxCurvY(i);  % latitude 
        Data(i).Lon = data.newMaxCurvX(i);  % longitude 
        Data(i).Latitude = data.newMaxCurvY(i);  % latitude attribute
        Data(i).Longitude = data.newMaxCurvX(i);  % longitude attribute
        Data(i).ID  = i;  
    end
    
    shapewrite(Data, strcat(path, file));
    
    waitbar(1, hwait);
    delete(hwait);
    
end


% --------------------------------------------------------------------
function export_bends_data_table_Callback(hObject, eventdata, handles)
% hObject    handle to export_bends_data_table (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

geovar=getappdata(0, 'geovar');
handles.ChannelSel=get(handles.popupChannel,'Value')-1;

if(handles.ChannelSel == 0)
    %No action
else
    
    %Open save file window (only txt file format for now)
    [file,path] = uiputfile('*.txt', 'Export bends data as table', 'bends_data_table');

    %get data from geovar and selected channel
    data = geovar{handles.ChannelSel};
   
    hwait = waitbar(0,'Exporting Excel File...');

    fid = fopen(strcat(path, file),'wt');

    generalHeaders = ["Total bends", "Total length", "Date created"];
    generalValues = [convertCharsToStrings(num2str(data.nBends)), convertCharsToStrings(num2str(data.intS(end,1))), convertCharsToStrings(datestr(now))];

    for i = 1:length(generalHeaders)
        fprintf(fid,'%s',generalHeaders(1,i));
        fprintf(fid,'\t');
        fprintf(fid,'%s',generalValues(1,i));
        fprintf(fid,'\n');
    end

    fprintf(fid,'\n');

    waitbar(1/3, hwait);

    dataHeaders = ["Bend ID", "Sinuosity", "Arc Wavelength", "Wavelength", "Amplitude", "Downstream length", "Upstream length", "Condition"];

    for i = 1:length(dataHeaders)
        fprintf(fid,'%s',dataHeaders(1,i));
        fprintf(fid,'\t\t');
    end

    fprintf(fid,'\n');

    for i = 1:data.nBends
        fprintf(fid,'%s',convertCharsToStrings(num2str(data.bendID1(i))));
        fprintf(fid,'\t\t');
        fprintf(fid,'%s',convertCharsToStrings(num2str(data.sinuosityOfBends(i))));
        fprintf(fid,'\t\t\t');
        if (isnan(data.lengthCurved(i)) || data.lengthCurved(i) <= 0); fprintf(fid,'%s',"0000.0000"); else; fprintf(fid,'%s',convertCharsToStrings(num2str(data.lengthCurved(i)))); end
        fprintf(fid,'\t\t');
        if (isnan(data.wavelengthOfBends(i)) || data.wavelengthOfBends(i) <= 0); fprintf(fid,'%s',"0000.0000"); else; fprintf(fid,'%s',convertCharsToStrings(num2str(data.wavelengthOfBends(i)))); end
        fprintf(fid,'\t\t');
        if (isnan(data.amplitudeOfBends(i)) || data.amplitudeOfBends(i) <= 0); fprintf(fid,'%s',"0000.0000"); else; fprintf(fid,'%s',convertCharsToStrings(num2str(data.amplitudeOfBends(i)))); end
        fprintf(fid,'\t\t');
        if (isnan(data.downstreamSlength(i)) || data.downstreamSlength(i) <= 0); fprintf(fid,'%s',"0000.0000"); else; fprintf(fid,'%s',convertCharsToStrings(num2str(data.downstreamSlength(i)))); end
        fprintf(fid,'\t\t\t');
        if (isnan(data.upstreamSlength(i)) || data.upstreamSlength(i) <= 0); fprintf(fid,'%s',"0000.0000"); else; fprintf(fid,'%s',convertCharsToStrings(num2str(data.upstreamSlength(i)))); end
        fprintf(fid,'\t\t\t');
        fprintf(fid,'%s',data.condition{i});
        fprintf(fid,'\n');
    end

    fprintf(fid,'\n');
    fprintf(fid,'%s',"Mean Values");
    fprintf(fid,'\n\n');

    waitbar(2/3, hwait);

    meanDataHeaders = ["Sinuosity", "Arc_Wavelength", "Wavelength", "Amplitude", "Condition"];

    for i = 1:length(meanDataHeaders)
        fprintf(fid,'%s',meanDataHeaders(1,i));
        fprintf(fid,'\t\t');
    end

    [s,~,j] = unique(data.condition);

    fprintf(fid,'\n');

    fprintf(fid,'%s',convertCharsToStrings(round(nanmean(data.sinuosityOfBends), 2)));
    fprintf(fid,'\t\t');
    fprintf(fid,'%s',convertCharsToStrings(round(nanmean(data.lengthCurved), 2)));
    fprintf(fid,'\t\t');
    fprintf(fid,'%s',convertCharsToStrings(round(nanmean(data.wavelengthOfBends), 2)));
    fprintf(fid,'\t\t');
    fprintf(fid,'%s',convertCharsToStrings(round(nanmean(data.amplitudeOfBends), 2)));
    fprintf(fid,'\t\t');
    fprintf(fid,'%s', s{mode(j)});
    fprintf(fid,'\n');

    waitbar(1, hwait);
    delete(hwait)

    fclose(fid); 
    
end
