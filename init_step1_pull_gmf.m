clear;
clc;
close all force;
close all;
app=NaN(1);  %%%%%%%%%This is to allow for Matlab Application integration.
format shortG
top_start_clock=clock;
folder1='C:\Users\nlasorte\OneDrive - National Telecommunications and Information Administration\MATLAB2024\2.7GHz Retuning';  %%%%%%%%This is the folder where you put the github repo
cd(folder1)
pause(0.1)
addpath(folder1)
addpath('C:\Users\nlasorte\OneDrive - National Telecommunications and Information Administration\MATLAB2024\GMF_functions')
addpath('C:\Users\nlasorte\OneDrive - National Telecommunications and Information Administration\MATLAB2024\Basic_Functions')
addpath('C:\Users\nlasorte\OneDrive - National Telecommunications and Information Administration\MATLAB2024\Retuning_Functions')


%Most of the structure for the p2p retuning seems a bit unnecessay for the radar retuning.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%First pull the GMF to get the Lat/Lon Locations and the Current Frequencies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tf_repull_gmf=0%1
data_num=1
cell_data_filename1=strcat('cell_gmf_retune_data_',num2str(data_num),'.mat');
[var_exist]=persistent_var_exist_with_corruption(app,cell_data_filename1);
if tf_repull_gmf==1
    var_exist=0;
end
if var_exist==2
    load(cell_data_filename1,'cell_gmf_retune_data')
else

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%GMF inputs
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    cd(folder1)
    pause(0.1)
    gmf_MinMHz=2690;
    gmf_MaxMHz=3000;
    rev_num=0822026

    %[gmf_table]=pull_gmf_excel_onedrive_rev3(app,gmf_MinMHz,gmf_MaxMHz,rev_num,folder1);
    [gmf_table]=pull_gmf_excel_onedrive_rev2(app,gmf_MinMHz,gmf_MaxMHz,rev_num);
    gmf_header=gmf_table.Properties.VariableNames;
    cell_gmf=table2cell(gmf_table);

    %%%%%%%%Header IDX
    service_col_idx=find(matches(gmf_header,'Service'));
    col_agency_idx=find(matches(gmf_header,'Agency'));
    col_gmf_ser_idx=find(matches(gmf_header,'SER'));
    col_gmf_freq1_idx=find(matches(gmf_header,'FRQMHz'));
    city_col_idx=find(matches(gmf_header,'XAL'));
    equ_col_idx=find(matches(gmf_header,'XEQ'));
    col_lat_idx=find(matches(gmf_header,'XLatDD'));
    col_lon_idx=find(matches(gmf_header,'XLonDD'));

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Cut
    %%%%%%%%%%%%%Filter out CAN and NG
    ng_idx=find(contains(cell_gmf(:,col_gmf_ser_idx),'NG'));  %%%%%%Non-Government
    cell_gmf(ng_idx,:)=[];
    can_idx=find(contains(cell_gmf(:,col_gmf_ser_idx),'CAN'));   %%%%Cananda
    cell_gmf(can_idx,:)=[];
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Simplifiy the Agency Name in the GMF
    [cell_gmf]=simplify_gmf_agency_name_rev1(app,cell_gmf,gmf_header);
    %%%%%%%%%%Unique Agency Types
    unique(cell_gmf(:,col_agency_idx))
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Unique other strings in the GMF and remove N/A  or NaN
    header_string='XAG';
    [cell_gmf]=unique_and_remove_nan_rev1(app,gmf_header,header_string,cell_gmf);
    header_string='XAH';
    [cell_gmf]=unique_and_remove_nan_rev1(app,gmf_header,header_string,cell_gmf);
    header_string='STC';
    [cell_gmf]=unique_and_remove_nan_rev1(app,gmf_header,header_string,cell_gmf);
    header_string='PWR';
    [cell_gmf]=unique_and_remove_nan_rev1(app,gmf_header,header_string,cell_gmf);
    header_string='RAG';
    [cell_gmf]=unique_and_remove_nan_rev1(app,gmf_header,header_string,cell_gmf);
    header_string='RAH';
    [cell_gmf]=unique_and_remove_nan_rev1(app,gmf_header,header_string,cell_gmf);
    header_string='RAL';
    [cell_gmf]=unique_and_remove_nan_rev1(app,gmf_header,header_string,cell_gmf);
    header_string='RSC';
    [cell_gmf]=unique_and_remove_nan_rev1(app,gmf_header,header_string,cell_gmf);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Clean up the Tx EUT name and fill in holes
    [cell_gmf]=clean_gmf_tx_eut_rev1(app,gmf_header,cell_gmf);

    %%%%%%%%%Clean up the Lat/Lon, if missing --> NAN
    [cell_gmf]=clean_gmf_tx_latlon_rev1(app,gmf_header,cell_gmf);


    %%%%%%%%%%%%%%Easier to just separate it here
    %%%%%%%%%%%NOAA/NEXRAD locations
    met_idx=find(contains(cell_gmf(:,service_col_idx),'Meteorological Aids'));
    met_gmf=cell_gmf(met_idx,:);
    met_com_idx=find(contains(met_gmf(:,col_agency_idx),'Commerce'));
    com_met_gmf=met_gmf(met_com_idx,:);
    table_comm_met=cell2table(com_met_gmf);
    [~,sort_name_idx]=sortrows(table_comm_met(:,city_col_idx));
    sort_table_comm_met=table_comm_met(sort_name_idx,:);
    sort_table_comm_met.Properties.VariableNames=gmf_header;
    %writetable(sort_table_comm_met,strcat('table_comm_met_',num2str(rev_num),'.xlsx'));     %%%%%%%%%%First raw set of Data as input


    %%%%%%%%%%FAA ASR-9/11 Locations
    aero_idx=find(contains(cell_gmf(:,service_col_idx),'Aeronautical Radionavigation'));
    aero_gmf=cell_gmf(aero_idx,:);
    faa_idx=find(contains(aero_gmf(:,col_agency_idx),'FAA'));
    faa_areo_gmf=aero_gmf(faa_idx,:);
    table_faa_areo=cell2table(faa_areo_gmf);
    [~,sort_name2_idx]=sortrows(table_faa_areo(:,city_col_idx));
    sort_table_faa_areo=table_faa_areo(sort_name2_idx,:);
    sort_table_faa_areo.Properties.VariableNames=gmf_header;
    %writetable(sort_table_faa_areo,strcat('table_faa_areo',num2str(rev_num),'.xlsx'));    %%%%%%%%%%First raw set of Data as input


    %%%%%%%%%%%%%%Find the unique locations/equipment (lat,lon,height
    table_faa_noaa=vertcat(sort_table_comm_met,sort_table_faa_areo);
    temp_gmf_data=table2cell(table_faa_noaa);
    temp_gmf_data(1:10,:)

    %%%%%Fix the Equipment Names
    unique(temp_gmf_data(:,equ_col_idx))

    [num_gmf,~]=size(temp_gmf_data);
    for gmf_idx=1:1:num_gmf
        temp_tx_eut_name=temp_gmf_data{gmf_idx,equ_col_idx};
        if contains(temp_tx_eut_name,'ASR-8')
            temp_tx_eut_name='ASR8';
        end

        if contains(temp_tx_eut_name,'ASR-11')
            temp_tx_eut_name='ASR11';
        end

        if contains(temp_tx_eut_name,'ASR-9')
            temp_tx_eut_name='ASR9';
        end

        if contains(temp_tx_eut_name,'WSR')
            temp_tx_eut_name='WSR88D';
        end

        temp_gmf_data{gmf_idx,equ_col_idx}=temp_tx_eut_name;
    end
      %%%%%Fix the Equipment Names
    unique(temp_gmf_data(:,equ_col_idx))

    cell_uni_strings=cell(6,1);
    cell_uni_strings{1}='XLatDD';
    cell_uni_strings{2}='XLonDD';
    cell_uni_strings{3}='XAH';
    cell_uni_strings{4}='XAL';
    cell_uni_strings{5}='XSC';
    cell_uni_strings{6}='XEQ';

    [table_uni_rows,ia,ic]=uniqe_gmf_rows_rev2_no_print(app,gmf_header,cell_uni_strings,temp_gmf_data);
    [~,sort_name_idx]=sortrows(table_uni_rows(:,4));
    sort_table_uni=table_uni_rows(sort_name_idx,:);
    sort_table_uni.Properties.VariableNames=cell_uni_strings
    %writetable(sort_table_uni_faa,strcat('table_unique_faa_areo',num2str(rev_num),'.xlsx'));

    %%%%%%%%%Use ic to merge each row.
    num_uni=height(table_uni_rows);
    cell_uni_row_idx=accumarray(ic,(1:numel(ic))',[num_uni 1],@(x){sort(x)});

    num_uni=length(cell_uni_row_idx)
    cell_gmf_retune_data=cell(num_uni,7); %%%%%%1)GMF Serial, 2)GMF Freq, 3) City, 4)Equipment, 5)Lat, 6)Lon, 7)Unique Name with num_uni #
    for i=1:1:num_uni
        temp_idx=cell_uni_row_idx{i};
        temp_gmf_row=temp_gmf_data(temp_idx,:);
        cell_gmf_retune_data{i,1}=unique(vertcat(temp_gmf_row(:,col_gmf_ser_idx)));
        cell_gmf_retune_data{i,2}=unique(cell2mat(vertcat(temp_gmf_row(:,col_gmf_freq1_idx))));
        cell_gmf_retune_data(i,3)=unique(vertcat(temp_gmf_row(:,city_col_idx)));
        cell_gmf_retune_data(i,4)=unique(vertcat(temp_gmf_row(:,equ_col_idx)));
        cell_gmf_retune_data{i,5}=unique(cell2mat(vertcat(temp_gmf_row(:,col_lat_idx))));
        cell_gmf_retune_data{i,6}=unique(cell2mat(vertcat(temp_gmf_row(:,col_lon_idx))));
        cell_agency_letter=cellfun(@(s) s(isletter(s)), temp_gmf_row(1,col_gmf_ser_idx), 'UniformOutput', false);
        cell_gmf_retune_data(i,7)=strcat(cell_agency_letter{1},num2str(i),temp_gmf_row(1,equ_col_idx));
    end
    save(cell_data_filename1,'cell_gmf_retune_data')
end
