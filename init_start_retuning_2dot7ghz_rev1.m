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



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Second: Calculate the RFS and make the data into the form we need
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tf_calc_rfs=0%1
data_num=1
cell_data_filename2=strcat('cell_nonzero_deltaF_',num2str(data_num),'.mat');
[var_exist]=persistent_var_exist_with_corruption(app,cell_data_filename2);
if tf_calc_rfs==1
    var_exist=0;
end
if var_exist==2
    load(cell_data_filename2,'cell_nonzero_deltaF')
else
    %%%%%%%%For Now, just calculate the distance put a RFS, but this is
    %%%%%%%%where we would do the link budget RFS
    %%%%%%This is just an approximation for placeholder values. Scatter plot from Haberman RFS

    array_latlon=cell2mat(cell_gmf_retune_data(:,[5,6]));
    [num_pts,~]=size(array_latlon)
    array_rfs=NaN(num_pts,num_pts);
    tic;
    for i=1:1:num_pts
        temp_dist_km=deg2km(distance(array_latlon(i,1),array_latlon(i,2),array_latlon(:,1),array_latlon(:,2)));

        %%%%%%<35km == 1mhz
        idx1=find(temp_dist_km<350);
        array_rfs(i,idx1)=1;

        %%%%%%<250km == 2mhz
        idx2=find(temp_dist_km<250);
        array_rfs(i,idx2)=2;

        %%%%%%<200km == 3mhz
        idx3=find(temp_dist_km<200);
        array_rfs(i,idx3)=3;

        %%%%%%<150km == 6mhz
        idx4=find(temp_dist_km<150);
        array_rfs(i,idx4)=6;

        %%%%%%<100km == 10mhz
        idx5=find(temp_dist_km<100);
        array_rfs(i,idx5)=10;

        %%%%%%<50km == 20mhz
        idx6=find(temp_dist_km<50);
        array_rfs(i,idx6)=20;

        %%%%%%<20km == 40mhz
        idx7=find(temp_dist_km<20);
        array_rfs(i,idx7)=40;

        %%%%%%%%%%%%Zero to NaN
        zero_idx=find(temp_dist_km==0);
        array_rfs(i,zero_idx)=NaN(1,1);
    end
    toc;

    array_tri_rfs=triu(array_rfs);
    array_tri_rfs(array_tri_rfs==0)=NaN(1,1);
    [row_idx,col_idx]=find(~isnan(array_tri_rfs));
    num_rfs=nnz(~isnan(array_tri_rfs))
    cell_nonzero_deltaF=cell(num_rfs,15);
    for i=1:1:num_rfs
        temp_name1=cell_gmf_retune_data{row_idx(i),1};

        cell_nonzero_deltaF{i,1}=cell_gmf_retune_data{row_idx(i),7};
        cell_nonzero_deltaF{i,2}=erase(temp_name1{1}," ");  %%%Remove the Spaces/Site A
        if length(temp_name1)>1
            cell_nonzero_deltaF{i,3}=erase(temp_name1{2}," ");  %%%Remove the Spaces/Site A
        else
            cell_nonzero_deltaF{i,3}=erase(temp_name1{1}," ");  %%%Remove the Spaces/Site B
        end
        cell_nonzero_deltaF{i,4}='V';
        cell_nonzero_deltaF{i,5}='V';

        temp_name2=cell_gmf_retune_data{col_idx(i),1};
        cell_nonzero_deltaF{i,7}=erase(temp_name2{1}," ");  %%%Remove the Spaces/Site C
        if length(temp_name2)>1
            cell_nonzero_deltaF{i,8}=erase(temp_name2{2}," ");  %%%Remove the Spaces/Site D
        else
            cell_nonzero_deltaF{i,8}=erase(temp_name2{1}," ");  %%%Remove the Spaces/Site D
        end
        cell_nonzero_deltaF{i,6}=cell_gmf_retune_data{col_idx(i),7};
        cell_nonzero_deltaF{i,9}='V';
        cell_nonzero_deltaF{i,10}='V';
        cell_nonzero_deltaF{i,11}='A->C';
        cell_nonzero_deltaF{i,12}='A';
        cell_nonzero_deltaF{i,13}='C';
        cell_nonzero_deltaF{i,15}=array_tri_rfs(row_idx(i),col_idx(i));
    end
    cell_nonzero_deltaF(1:10,:)

    %%%%%%%%%%%%%%%%All Non-NaN RFS
    %%%%%%%%%Need to put it into this.
  %%%%%%%%%%%%%Carry Over form from the p2p
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % % % % % % % % % % % % % % % % % % % % % 1) Design LinkID
    % % % % % % % % % % % % % % % % % % % % % 2) Design Site ID A
    % % % % % % % % % % % % % % % % % % % % % 3) Design Site ID B
    % % % % % % % % % % % % % % % % % % % % % 4) Design A Polarization
    % % % % % % % % % % % % % % % % % % % % % 5) Design B Polarization
    % % % % % % % % % % % % % % % % % % % % % 6) Environment LinkID
    % % % % % % % % % % % % % % % % % % % % % 7) Envir Site ID C
    % % % % % % % % % % % % % % % % % % % % % 8) Envir Site ID D
    % % % % % % % % % % % % % % % % % % % % % 9) Envir C Polarization
    % % % % % % % % % % % % % % % % % % % % % 10) Envir D Polarization
    % % % % % % % % % % % % % % % % % % % % % 11) Config String
    % % % % % % % % % % % % % % % % % % % % % 12) Config Tx A/B/C/D
    % % % % % % % % % % % % % % % % % % % % % 13) Config Rx A/B/C/D
    % % % % % % % % % % % % % % % % % % % % % 14) Full Freq DeltaF (minimum GMF RFS)
    % % % % % % % % % % % % % % % % % % % % % 15) Delta F
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    save(cell_data_filename2,'cell_nonzero_deltaF')
end


%%%%%%%%%%%%Need to make the "channel plan"
tf_calc_plan=0%1%0%1
channel_plan_num=5
filename_full_channel_plan=strcat('full_channel_plan_',num2str(channel_plan_num),'.mat')
[var_exist]=persistent_var_exist_with_corruption(app,filename_full_channel_plan);
if tf_calc_plan==1
    var_exist=0;
end
if var_exist==2
    load(filename_full_channel_plan,'full_channel_plan')
else
    full_channel_plan=cell(2,6);
    full_channel_plan{1,1}='1MHz';
    full_channel_plan{1,2}='A';
    full_channel_plan{1,6}=1;

    %%%2700-2900mhz channel plan A
    freq_steps=2700:1:2900;
    num_steps=length(freq_steps);
    cell_aplan=cell(num_steps,4);
    for i=1:1:num_steps
        cell_aplan{i,1}=strcat('A',num2str(i));
        cell_aplan{i,2}='A';
        cell_aplan{i,3}=i;
        cell_aplan{i,4}=freq_steps(i);
    end
    full_channel_plan{1,3}=cell_aplan;

    %%%2700-3000mhz channel plan B
    full_channel_plan{2,1}='1MHz';
    full_channel_plan{2,2}='B';
    full_channel_plan{2,6}=1;
    freq_steps=2700:1:3000;
    num_steps=length(freq_steps);
    cell_bplan=cell(num_steps,4);
    for i=1:1:num_steps
        cell_bplan{i,1}=strcat('B',num2str(i));
        cell_bplan{i,2}='B';
        cell_bplan{i,3}=i;
        cell_bplan{i,4}=freq_steps(i);
    end
    full_channel_plan{2,3}=cell_bplan;
    save(filename_full_channel_plan,'full_channel_plan')
end
full_channel_plan



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Set the Simulation Inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rev_num=1001 %%%%%%%%%%%%%Test for 2.7ghz
sim_data_label='test2dot7'
bottom_hole_freq=2700;
array_top_hole_freq=2800
array_freq_hole_set=NaN(length(array_top_hole_freq),2);
array_freq_hole_set(:,2)=array_top_hole_freq;
array_freq_hole_set(:,1)=bottom_hole_freq
max_pop_size=4%2%32%64%4%8%512%64;  %%%%Make the max pop size, number of links x 2.
pop_size=4%2%32%16%4%16%4;%8%8%16%8%512%64%32%64%16%512%32%4;
max_iter=50%500;
max_num_no_change=3%4 %%%%%%%%%%%%%%%Testing max_num_no_change for this rev: This should be the number of links in the sim?
[array_node_step,~]=size(cell_gmf_retune_data) %%%%Linear horzcat(1,2,3,4,6,8,12,16,24,32,48,64,96,128,192,256,384,512,768,1024,1536,2048,3072,4096,8192); %%%%%Binaray + Half Step
main_sim_folder='C:\Local Matlab Data\2.7GHz Local Retuning'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% array_num=cell2mat(sort_cell_cluster_groups_latlon_dist(:,3));
% find_idx=find(array_num==10);
% find_idx=find_idx(1)
% array_num(find_idx(1))
% cell_sim_data=cell(1,2);
% cell_sim_data{1,1}=sort_cell_cluster_groups_latlon_dist{find_idx,1}
% cell_sim_data{1,2}=unique(vertcat(sort_cell_cluster_groups_latlon_dist{find_idx,2}))
% excel_filename_solution=''
% tf_use_solution=0%1
% tf_expand=0%1
% tf_circ_shift=0 %%%%%%%%Only use the solution, no circ shift


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tf_invert_channels=0;  %%%%%%%If 1 --> Allow the inverted channel options, where we switch the frequency at A/B. If 0, the low frequency is at A, high frequency at B
tf_custom_channel_plan=0;  %%%%%Will need to add this logic if we enable it
tf_just_vert_channels=1;  %%%%%%%1/0, If 1 --> Just the Vertical Channels, if 0 --> H and V Channels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Create a Rev Folder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd(main_sim_folder);
pause(0.1)
tempfolder=strcat('Rev',num2str(rev_num));
[status,msg,msgID]=mkdir(tempfolder);
rev_folder=fullfile(main_sim_folder,tempfolder);
retry_cd=1;
while(retry_cd==1)
    try
        cd(rev_folder)
        pause(0.1);
        retry_cd=0;
    catch
        retry_cd=1;
        pause(0.1)
    end
end
pause(0.1)


%%%%%%%%%%%%%For the Server:
cd(rev_folder)
pause(0.1)
tic;
save('pop_size.mat','pop_size')
save('rev_num.mat','rev_num')
save('max_iter.mat','max_iter')
save('max_num_no_change.mat','max_num_no_change')
save('max_pop_size.mat','max_pop_size')
save('array_freq_hole_set.mat','array_freq_hole_set')
save('array_node_step.mat','array_node_step')
save('cell_nonzero_deltaF.mat','cell_nonzero_deltaF') 
toc;  %%%%%%%500 links --> xx seconds


[num_freq,~]=size(array_freq_hole_set)
for freq_hole_idx=1:1:num_freq
    freq_hole_set=array_freq_hole_set(freq_hole_idx,:)
    %%%%%%%%This just cut the frequencies
    [mod_full_channel_plan]=expand_full_channel_plan_rev3_simplify(app,full_channel_plan,freq_hole_set);




   

    

    'next step with the simplification'
    pause;



    tic;
    %%%[cell_temp_channels]=allocate_available_freq_p2p_rev3(app,cell_system_info,mod_full_channel_plan,cell_nonzero_deltaF);
    [cell_temp_channels]=allocate_available_freq_p2p_while_fit_rev4(app,cell_system_info,mod_full_channel_plan,sort_cell_expanding_weights_idx);
    toc;
    save(strcat('cell_temp_channels_',num2str(freq_hole_set(1)),'_',num2str(freq_hole_set(2)),'.mat'),'cell_temp_channels')

    %%%%%%%%%%Fall Back Frequency Set
    fallback_freq_hole_set=array_freq_hole_set(end,:)
    fallback_freq_hole_set(2)=fall_back_freq
    tic;
    [fallback_mod_full_channel_plan]=expand_full_channel_plan_rev2_just_vert(app,full_channel_plan,tf_custom_channel_plan,fallback_freq_hole_set,tf_just_vert_channels,tf_invert_channels);
    toc;
    tic;
    [cell_temp_channels_fallback]=allocate_available_freq_p2p_while_fit_rev4(app,cell_system_info,fallback_mod_full_channel_plan,sort_cell_expanding_weights_idx);
    toc;
    save(strcat('cell_temp_channels_fallback.mat'),'cell_temp_channels_fallback')


end

'need to simplify the code from the p2p channel plan'
pause;


    'start here after the channels'
    pause;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%App Wrapper Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



'starting here to try to fit it into the Genetic algorithm'
pause;




 %%%Let's have it do it in the   full_ga_p2p_pop_chunks_expand_node_freq_topfreqrand_rev11





    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Another Check
    %%%%%%%%%%%%%'Match the cell_p2p_linklist and cell_expand_split_list
    [cell_system_info]=pretunning_match_link_list_rev1(app,cell_p2p_linklist,cell_expand_split_list);

 tic;
 [cell_temp_channels_fallback]=allocate_available_freq_p2p_while_fit_rev4(app,cell_system_info,fallback_mod_full_channel_plan,sort_cell_expanding_weights_idx);
 toc;




'Going into the full ga'
pause;
%%%function [table_freq,tf_int]=full_ga_p2p_pop_chunks_expand_node_freq_topfreqrand_rev11(app,pop_size,tf_skip_to_end,parallel_flag,workers,tf_server_status,freq_hole_set)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Function: full_ga_p2p_pop_chunks_expand_node_freq_topfreqrand_rev11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%For the Server:
tic;
[rev_num]=load_data_rev_num(app);
[max_iter]=load_data_max_iter(app);
[max_num_no_change]=load_data_max_num_no_change(app);
[cell_temp_channels]=load_data_cell_temp_channels_rev2(app,freq_hole_set);
[array_node_step]=load_data_array_node_step(app);
[cell_nonzero_deltaF]=load_data_cell_nonzero_deltaF(app);  
[cell_temp_channels_fallback]=load_data_cell_temp_channels_fallback(app);


 %%%%%[simple_sort_cell_expanding_weights_idx]=load_data_simple_sort_cell_expanding_weights_idx(app);
 tic;
 [sort_cell_expanding_weights_idx]=weight_idx_cut_deltaF_rev3(app,cell_nonzero_deltaF);
 toc; %%%%%0.1 Seconds
 simple_sort_cell_expanding_weights_idx=sort_cell_expanding_weights_idx;

 %%%%%%%This is used:  Let's have it do it in the   full_ga_p2p_pop_chunks_expand_node_freq_topfreqrand_rev11, where we feed it the   cell_nonzero_deltaF
 %%%%%%%%%%[cell_cell_sort_deltaF_check_idx]=load_data_cell_cell_sort_deltaF_check_idx(app);
 tic;
 [cell_cell_sort_deltaF_check_idx]=sort_deltaF_rows_while_fit_rev2(app,sort_cell_expanding_weights_idx,cell_nonzero_deltaF);
 toc;
 sort_cell_nonzero_deltaF=vertcat(cell_cell_sort_deltaF_check_idx{:});



 'Stop here and check'
 pause;


server_status_rev2(app,tf_server_status)
disp_progress(app,strcat('full_ga_p2p:Line 17:Post-Server Status'))
toc;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Find the Max fitness
all_deltaF_idx=unique(cell2mat(simple_sort_cell_expanding_weights_idx(:,4)));
max_fitness=length(unique(vertcat(sort_cell_nonzero_deltaF(all_deltaF_idx,1),sort_cell_nonzero_deltaF(all_deltaF_idx,6))));
[num_assign,~]=size(cell_temp_channels);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Limit the top of the array node
[num_weight_nodes,~]=size(simple_sort_cell_expanding_weights_idx);
keep_step_idx=find(array_node_step<num_weight_nodes);
array_node_step=unique(horzcat(array_node_step(keep_step_idx),num_weight_nodes));
%%%'limit array node step, where last number is the number of systems'


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Load the last set of DNA
%%%%%%%%Save the DNA each generation, as a way to pick up in the middle of a simulation
disp_progress(app,strcat('full_ga_p2p:Line 36:In to :load_last_dna_rev1'))
[iter_count,cell_full_pop_dna]=load_last_dna_rev1(app,tf_skip_to_end,pop_size,freq_hole_set); %%%%%%%%%%%%There was a var_exist_with_corruption deleteing in this function.
disp_progress(app,strcat('full_ga_p2p:Line 38:Out of :load_last_dna_rev1'))


tic;
if iter_count==0%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Initilize the Populations
    %'Randomizing the population . . .'


    node_idx=1;
    cell_full_pop_dna=cell(pop_size,13);
    rng(iter_count+rev_num);%For Repeatability of randomness
    'New code for max/top randomization'
    for pop_idx=1:1:pop_size
        temp_cell_single_dna=cell(num_assign,2); %%%%%%%%%1) Link Id, 2) Randomized channel
        for temp_group_idx=1:1:num_assign
            temp_cell_single_dna{temp_group_idx,1}=cell_temp_channels{temp_group_idx,1};
            temp_channels=cell_temp_channels{temp_group_idx,2};
            array_max_temp_channels_freq=max(cell2mat(temp_channels(:,[4,5])),[],2);
            [~,sort_desc_idx]=sort(array_max_temp_channels_freq,'descend');%%%%%%%Will be used later for mutations

            
% % %             max_freq=max(array_max_temp_channels_freq);
% % %             max_idx=find(array_max_temp_channels_freq==max_freq);
% % %             max_temp_channels=temp_channels(max_idx,:);
% % %             %%%%%%%%%%%%'randomize from the top'
% % %             [num_rand_opt,~]=size(max_temp_channels);
% % %             temp_rand_freq_idx=datasample([1:1:num_rand_opt],1);  %%%%%%
% % %             temp_cell_single_dna{temp_group_idx,2}=max_temp_channels(temp_rand_freq_idx,:);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%'sort channels by frequencies'
            %%%%%%%%Do the top half of the frequencies for the randomization
            top_sort_temp_channels=temp_channels(sort_desc_idx,:);
            [num_rand_opt,~]=size(top_sort_temp_channels);
            top_half_num=ceil(num_rand_opt/2)
            temp_rand_freq_idx=datasample([1:1:top_half_num],1);  %%%%%%
            temp_cell_single_dna{temp_group_idx,2}=top_sort_temp_channels(temp_rand_freq_idx,:);

  

            
            % % % % %                                                 %%%%%%%%%%%Fullrandomization used in the past
            % % % % %                                                 [num_rand_opt,~]=size(temp_channels);
            % % % % %                                                 temp_rand_freq_idx=datasample([1:1:num_rand_opt],1);  %%%%%%
            % % % % %                                                 temp_cell_single_dna{temp_group_idx,2}=temp_channels(temp_rand_freq_idx,:);
        end
        cell_full_pop_dna{pop_idx,1}=temp_cell_single_dna;
        cell_full_pop_dna{pop_idx,8}=iter_count;  %%%%%%%%%%Generation Randomized
        cell_full_pop_dna{pop_idx,13}=node_idx;
        %%cell_full_pop_dna{pop_idx,14}='';
    end

    % % % % % % % % % %     sort_cell_full_dna_weight -->  cell_full_pop_dna
    % % % % % % % % % %     1)DNA
    % % % % % % % % % %     2)Fitness
    % % % % % % % % % %     3)uni_parent_idx
    % % % % % % % % % %     4)Top interference-free node (name)
    % % % % % % % % % %     5)Top interference-free node (number)
    % % % % % % % % % %     6)uni_dna_idx (to figure out which one was a parent/first/second
    % % % % % % % % % %     7) 1 --> Parent, 2 ==> First Mut, 3 ~~> Second Mut
    % % % % % % % % % %     8) Generated Generated (iter_count) if empty enter the current iter_count
    % % % % % % % % % %     9) parent_int_idx/first_int_idx/second_int_idx
    % % % % % % % % % %     10) parent_vic_idx/first_vic_idx/second_vic_idx
    % % % % % % % % % %     11) node_idx that the fitness was evaluated (for the expand node)
    % % % % % % % % % %     12) array_node_step(node_idx) that the fitness was evaluated (for the expand node)
    % % % % % % % % % %     13) next_node_idx to check
    %%%%%%%%%%%%14) [Adding a column for the only check these changed frequencies]


    % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Genetic Algorithm Data
    % % % keep_num=NaN(1,4);          %%%Iteration, Parent, First, Second
    % % % stats_single_ga=NaN(1,3);   %%%Iteration Number, Max Fitness, Max Node Number
    % % % parent_stats=NaN(1,4);      %%%Iteration Number, Max Fitness, Max Node Number, Carry Over to Next Generation
    % % % first_mut_stats=NaN(1,4);   %%%Iteration Number, Max Fitness, Max Node Number, Carry Over to Next Generation
    % % % second_mut_stats=NaN(1,4);  %%%Iteration Number, Max Fitness, Max Node Number, Carry Over to Next Generation
    % % % cell_ga_data=cell(5,1);
    % % % cell_ga_data{1}=keep_num;
    % % % cell_ga_data{2}=stats_single_ga;
    % % % cell_ga_data{3}=parent_stats;
    % % % cell_ga_data{4}=first_mut_stats;
    % % % cell_ga_data{5}=second_mut_stats;
    % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %cell_ga_data=cell(5,1);
end
toc;  %%%%%%%%%1 second

%%%%%% temp_dna=cell_full_pop_dna{1,1}
%%%%%%%vertcat(temp_dna{:,2})


%%%%%%%%%%%%Check if the DNA was checked with the max node_idx and if it
%%%%%%%%%%%%has the max_fitness. If so . . . tf_stop==1 and we don't have
%%%%%%%%%%%%to do another generation
historic_pop_fitness=cell2mat(cell_full_pop_dna(:,2));
historic_node_check=cell2mat(cell_full_pop_dna(:,12));
if isempty(historic_node_check)
    historic_node_check=0;
end
if isempty(historic_pop_fitness)
    historic_pop_fitness=0;
end
%array_historic=horzcat(historic_pop_fitness,historic_node_check);

if max_fitness==max(historic_pop_fitness) && max(array_node_step)==max(historic_node_check)
    tf_stop=1;
else
    tf_stop=0;
end


while (tf_stop==0)
    [cell_temp_channels]=load_data_cell_temp_channels_rev2(app,freq_hole_set); %%%%%%%%%%%Loading again
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    iter_count=iter_count+1;
    disp_progress(app,strcat('full_ga_p2p:Line 138:iter_count:',num2str(iter_count)))  %%%%%%%%%%Error after this point with rev 2.2
    rng(iter_count+rev_num+num_assign);%For Repeatability of randomness
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%Find the node_idx from the cell_full_pop_dna
    node_idx=unique(cell2mat(cell_full_pop_dna(:,13)));
    if length(node_idx)>1
        node_idx=max(node_idx);
    end

    %%%%%%%No expanded node needed with the while fiteness (can clean this up later)
    %%%%%%%%%%%%Expanding Node Data
    node_step=array_node_step(node_idx);
    node_max_fitness=length(unique(vertcat(sort_cell_nonzero_deltaF(:,1),sort_cell_nonzero_deltaF(:,6))))

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Just in case
    [current_pop_size,~]=size(cell_full_pop_dna);
    if current_pop_size<pop_size
        cell_full_pop_dna=cell_full_pop_dna([1:current_pop_size],:);
        %%%%%disp_progress(app,strcat('The number of unique DNA is less than the pop_size: Need to create new randomized DNA'))
    elseif current_pop_size>pop_size
        cell_full_pop_dna=cell_full_pop_dna([1:pop_size],:);  %%%%%%%%%%We are doing this because are saving all the DNA of the previous generation
    end

    %%%%%%%%%%%%%%%Check the par/first/second generation column and update
    %%%%%%%%%%%%%%%those all to parent
    if iter_count>1
        % % % % % % % % % %     7) 1 --> Parent, 2 ==> First Mut, 3 ~~> Second Mut
        cell_full_pop_dna(:,7)=num2cell(1);
        %%'Update column 7 to 1, as these are now the parents'
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Rev 9 Chunk Fitness Pop
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%Don't save the unsorted, just the final.
    %%%%%%%%%%%First check is the cell_full_pop_dna is there
    disp_progress(app,strcat('full_ga_p2p:Line 178'))
    filename_pop_dna=strcat('cell_full_pop_dna_',num2str(pop_size),'_',num2str(iter_count),'_',num2str(freq_hole_set(1)),'_',num2str(freq_hole_set(2)),'.mat');  %%%%%%We only need to save the final dna
    [var_exist_cell_full_pop_dna]=persisent_file_exist_app(app,filename_pop_dna);%%%%The possible corruption is deleting it.
    disp_progress(app,strcat('full_ga_p2p:Line 181'))

    if var_exist_cell_full_pop_dna==2
        disp_progress(app,strcat('full_ga_p2p:Line 184'))
        %%%%%%%%'Load it'
        retry_load=1;
        while(retry_load==1)
            try
                load(filename_pop_dna,'cell_full_pop_dna')
                pause(0.1);
                retry_load=0;
            catch
                retry_load=1;
                pause(0.1)
            end
        end
    else
        [cell_temp_channels]=load_data_cell_temp_channels_rev2(app,freq_hole_set); %%%%%%%%Need to reload just in case, since we are updating it.
        [unsorted_cell_full_pop_dna]=check_fitness_rev1(app,filename_pop_dna,parallel_flag,pop_size,iter_count,freq_hole_set,cell_full_pop_dna,cell_cell_sort_deltaF_check_idx,cell_temp_channels,node_idx,array_node_step,node_max_fitness,tf_server_status,workers);
        disp_progress(app,strcat('full_ga_p2p:Line 187'))
        %%%%%Doesn't seem to get past this point

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Check Point: cell_full_pop_dna
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        disp_progress(app,strcat('full_ga_p2p:Line 192'))
        [var_exist_full_dna_second_check]=persisent_file_exist_app(app,filename_pop_dna);%%%%Check if it's there before proceeding, else skip to the end
        disp_progress(app,strcat('full_ga_p2p:Line 195'))
        if var_exist_full_dna_second_check==2
            %%%%%%%%Nothing
            disp_progress(app,strcat('full_ga_p2p:Line 198'))
        else
            %%%%%%%%%%%%%%Calculate it
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Unique DNA, Weight, and Sort by Node Number and Fitness
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%tic;
            disp_progress(app,strcat('full_ga_p2p:Line 206'))
            if isvector(unsorted_cell_full_pop_dna)
                disp_progress(app,strcat('ERROR: full_ga_p2p:Line 208: unsorted_cell_full_pop_dna is NaN'))
                pause;
            end
            new_cell_pop_dna=unsorted_cell_full_pop_dna;
            disp_progress(app,strcat('full_ga_p2p:Line 207:In to sort_simple_dna_weight_rev2'))
            [sort_cell_full_dna_weight]=sort_simple_dna_weight_rev2(app,new_cell_pop_dna,simple_sort_cell_expanding_weights_idx,node_max_fitness);
            disp_progress(app,strcat('full_ga_p2p:Line 209:Out of sort_simple_dna_weight_rev2'))
            %%%toc;  %%%%%% 0.057 seconds

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Save Data and Plot
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%tic;
            disp_progress(app,strcat('full_ga_p2p:Line 216:In to simple_save_ga_data_and_plot_update_rev5'))
            [tf_stop]=simple_save_ga_data_and_plot_update_rev5(app,pop_size,iter_count,freq_hole_set,sort_cell_full_dna_weight,max_fitness,max_iter,node_step,array_node_step,node_idx,node_max_fitness,rev_num,max_num_no_change);
            disp_progress(app,strcat('full_ga_p2p:Line 218:Out of simple_save_ga_data_and_plot_update_rev5'))
            %%%toc;  %%%%%0.048 seconds

            % % % % % % % % % %     sort_cell_full_dna_weight -->  cell_full_pop_dna
            % % % % % % % % % %     1)DNA
            % % % % % % % % % %     2)Fitness
            % % % % % % % % % %     3)uni_parent_idx
            % % % % % % % % % %     4)Top interference-free node (name)
            % % % % % % % % % %     5)Top interference-free node (number)
            % % % % % % % % % %     6)uni_dna_idx (to figure out which one was a parent/first/second (Not really needed at this point, but keep it)
            % % % % % % % % % %     7) 1 --> Parent, 2 ==> First Mut, 3 ~~> Second Mut
            % % % % % % % % % %     8) Generated Generated (iter_count) if empty enter the current iter_count
            % % % % % % % % % %     9) parent_int_idx/first_int_idx/second_int_idx
            % % % % % % % % % %     10) parent_vic_idx/first_vic_idx/second_vic_idx
            % % % % % % % % % %     11) node_idx that the fitness was evaluated (for the expand node)
            % % % % % % % % % %     12) array_node_step(node_idx) that the fitness was evaluated (for the expand node)
            % % % % % % % % % %     13) next_node_idx to check

            %previous_channels=cell_temp_channels(:,2);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Expanding Frequency for the single node.
            disp_progress(app,strcat('full_ga_p2p:Line 238'))
            [sort_cell_full_dna_weight,tf_stop]=expand_single_node_fallback_freq_rev1(app,freq_hole_set,sort_cell_full_dna_weight,tf_stop,cell_temp_channels_fallback,cell_cell_sort_deltaF_check_idx,node_max_fitness,max_fitness,array_node_step,node_idx);
            disp_progress(app,strcat('full_ga_p2p:Line 240'))
            [cell_temp_channels]=load_data_cell_temp_channels_rev2(app,freq_hole_set); %%%%%%%%%%%Loading again
            disp_progress(app,strcat('full_ga_p2p:Line 242'))


            %%%'Cut dna and save'
            %%%tic;
            %%%%cell_full_pop_dna=sort_cell_full_dna_weight(uni_keep_idx,:); %%%%%This would be the file to save.
            disp_progress(app,strcat('full_ga_p2p:Line 248'))
            cell_full_pop_dna=sort_cell_full_dna_weight; %%%%%This would be the file to save.
            disp_progress(app,strcat('full_ga_p2p:Line 250'))
            [current_pop_size,~]=size(cell_full_pop_dna);
            disp_progress(app,strcat('full_ga_p2p:Line 252'))
            if current_pop_size<pop_size
                disp_progress(app,strcat('full_ga_p2p:Line 254'))
                cell_full_pop_dna=cell_full_pop_dna([1:current_pop_size],:);
                disp_progress(app,strcat('The number of unique DNA is less than the pop_size: Need to create new randomized DNA'))
                %pause;
            elseif current_pop_size>pop_size
                disp_progress(app,strcat('full_ga_p2p:Line 259'))
                cell_full_pop_dna=cell_full_pop_dna([1:pop_size],:);  %%%%%%%%%%We are doing this because are saving all the DNA of the previous generation
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Check Point: cell_full_pop_dna
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        disp_progress(app,strcat('full_ga_p2p:Line 267'))
        [var_exist_full_dna_last_check]=persisent_file_exist_app(app,filename_pop_dna);%%%%Check if it's there before saving it.
        if var_exist_full_dna_last_check==2
            %%%%%%%%'Load it'
            disp_progress(app,strcat('full_ga_p2p:Line 271'))
            retry_load=1;
            while(retry_load==1)
                try
                    load(filename_pop_dna,'cell_full_pop_dna')
                    pause(0.1);
                    retry_load=0;
                catch
                    retry_load=1;
                    pause(0.1)
                end
            end
        else
            %%%%%%Save it
            disp_progress(app,strcat('full_ga_p2p:Line 285'))
            retry_save=1;
            while(retry_save==1)
                try
                    save(filename_pop_dna,'cell_full_pop_dna')
                    pause(0.1);
                    retry_save=0;
                catch
                    retry_save=1;
                    pause(0.1)
                end
            end
        end

        disp_progress(app,strcat('full_ga_p2p:Line 299'))
        %%%toc;%%%%%0.14 seconds
    end

    %%%%%%%%%%%This is where we clean
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'This is where we then clean up chunks'
    disp_progress(app,strcat('full_ga_p2p:Line 305:In To clean_dyanmic_chunks_p2p_rev2'))
    clean_pop_chunks_p2p_rev3(app,cell_full_pop_dna,pop_size,iter_count,freq_hole_set,filename_pop_dna)
    disp_progress(app,strcat('full_ga_p2p:Line 307:Ouf of clean_dyanmic_chunks_p2p_rev2'))
    server_status_rev2(app,tf_server_status)
    disp_progress(app,strcat('full_ga_p2p:Line 309:Post-Server Status'))

end %%%While Loop tf_stop (End of a generation)

disp_progress(app,strcat('full_ga_p2p:Line 313'))
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%End of Retuning function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Do one more check of the solution (single dna)
% 'Need to output temp_freq_solution and tf_int'

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Double Check
node_step=array_node_step(end);
check_node_idx=1:1:node_step;
deltaF_idx=unique(vertcat(simple_sort_cell_expanding_weights_idx{check_node_idx,4}));
cut_cell_nonzero_deltaF=sort_cell_nonzero_deltaF(deltaF_idx,:);
size(cut_cell_nonzero_deltaF)

[num_full_delta,~]=size(sort_cell_nonzero_deltaF)
[num_cut_delta,~]=size(cut_cell_nonzero_deltaF)

if num_full_delta~=num_cut_delta
    disp_progress(app,strcat('Pause Error on the cut vs full delta for the final check:full_ga_p2p:Line 474'))
    pause;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pop_idx=1
full_parent_dna=cell_full_pop_dna(pop_idx,:);
temp_cell_dna_single_pop=full_parent_dna{1};

tic;
[~,~,temp_double_check_fitness,uni_int_idx]=singlepop_expanding_fit_check_7GHz_rev4(app,temp_cell_dna_single_pop,cut_cell_nonzero_deltaF);
toc;

[num_links,~]=size(temp_cell_dna_single_pop);
array_int=zeros(num_links,1);

if max_fitness==temp_double_check_fitness
    disp_progress(app,strcat('Success: No Interference'))
    tf_int=0
else
    'Error: Double check has interference'
    'If there is interference, plot that on the map and find the nodes that have interference and output them to an excel.'
    tf_int=1

    number_int=length(unique(uni_int_idx));
    for i=1:1:number_int
        int_idx=find(matches(temp_cell_dna_single_pop(:,1),uni_int_idx{i}));
        array_int(int_idx)=1;
    end
    array_int
    %pause;
end


%%%'Also have the frequency holes for each node in additional columns'
[num_rows1,~]=size(cell_temp_channels);
cell_freq_span=cell(num_rows1,2);
for i=1:1:num_rows1
    temp_cell_freq=cell_temp_channels{i,2};
    temp_array_freq=reshape(cell2mat(temp_cell_freq(:,[4,5])),[],1);
    cell_freq_span{i,1}=min(temp_array_freq);
    cell_freq_span{i,2}=max(temp_array_freq);
end


disp_progress(app,strcat('full_ga_p2p:Line 534'))
number_int=length(unique(uni_int_idx))
table_freq=cell2table(horzcat(temp_cell_dna_single_pop(:,1),vertcat(temp_cell_dna_single_pop{:,2}),num2cell(array_int),cell_freq_span));
table_freq.Properties.VariableNames={'ID' 'Channel' 'Channel_Letter' 'Channel_Number' 'A_FREQ_MHz' 'B_FREQ_MHz' 'A_POL' 'B_POL' 'TF_Int' 'Min_Freq' 'Max_Freq'}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Histogram the Frequencies
cell_solution_set=vertcat(temp_cell_dna_single_pop{:,2});
array_freq_solution=cell2mat(cell_solution_set(:,[4,5]));
min_freq_solution=min(cell2mat(cell_solution_set(:,[4,5])),[],2);

%%%%%%%%%Bin based on 30Mhz
edges=horzcat(7125,7150:60:8500,8500);
figure;
hold on;
%histogram(min_freq_solution,edges)
histogram(array_freq_solution,edges)
xline(7750,'-r','LineWidth',3)
xticks(edges)
grid on;
title('Historgram: Minimum Frequnecy')
filename1=strcat('Histogram_Solution_',num2str(rev_num),'_',num2str(pop_size),'_',num2str(freq_hole_set(1)),'_',num2str(freq_hole_set(2)),'.png');
saveas(gcf,char(filename1))

tic;
retry_save=1;
while(retry_save==1)
    try
        excel_freq_filename=strcat('Output_Freq_RevNumb',num2str(rev_num),'_NumInterference',num2str(number_int),'_Pop',num2str(pop_size),'_FreqHole',num2str(freq_hole_set(1)),'_',num2str(freq_hole_set(2)),'.xlsx');
        writetable(table_freq,excel_freq_filename)
        pause(0.1);
        retry_save=0;
    catch
        retry_save=1;
        pause(0.1)
    end
end
toc;
disp_progress(app,strcat('Total Interference:',num2str(number_int),'---',num2str(freq_hole_set(1)),'-',num2str(freq_hole_set(2))))
disp_progress(app,strcat('full_ga_p2p:Line 553'))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%End Function: full_ga_p2p_pop_chunks_expand_node_freq_topfreqrand_rev11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
























end_clock=clock;
total_clock=end_clock-top_start_clock;
total_seconds=total_clock(6)+total_clock(5)*60+total_clock(4)*3600+total_clock(3)*86400;
total_mins=total_seconds/60;
total_hours=total_mins/60;
if total_hours>1
    strcat('Total Hours:',num2str(total_hours))
elseif total_mins>1
    strcat('Total Minutes:',num2str(total_mins))
else
    strcat('Total Seconds:',num2str(total_seconds))
end
close all force;
cd(folder1)
'Done'

