function [Migra]=mStat_Migration(geovar,handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Calculate the migration data
%Dominguez Ruben L. UNL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

init=1;%tinitial
ended=2;%tfinal

%Initial data
xstart=geovar{init}.equallySpacedX;
ystart=geovar{init}.equallySpacedY;

%Xstart mid point
for i=1:size(xstart,1)-1
    Xmidpoint(i,1)=(xstart(i+1,1)+xstart(i,1))/2;
    Ymidpoint(i,1)=(ystart(i+1,1)+ystart(i,1))/2;
end

%Finally data
xend=geovar{ended}.equallySpacedX;
yend=geovar{ended}.equallySpacedY;
% 

%%
%Define normal lines
%line1
dy=gradient(ystart);
dx=gradient(xstart);

for i=1:size(xstart,1)-1
    startpoint(i,:)=[xstart(i,1) ystart(i,1)];
    endpoint(i,:)=[xstart(i+1,1) ystart(i+1,1)];
    v(i,:)=1*(endpoint(i,:)-startpoint(i,:));
    

    xx(i,1)=xstart(i,1)+0.5*v(i,1);

    yy(i,1)=ystart(i,1)+0.5*v(i,2);

    v(i,:)=1000*v(i,:)/norm(v(i,:));
    
    xstart_line1(i,1)=xx(i,1)+v(i,2);
	xend_line1(i,1)=xx(i,1)-v(i,2);
	ystart_line1(i,1)=yy(i,1)-v(i,1);
	yend_line1(i,1)=yy(i,1)+v(i,1);
   
end

 clear startpoint endpoint

%  figure(3)
%     plot(xstart,ystart,'-b')%start
%     	hold on
%     plot(xend,yend,'-k')
%   for i=1:length(xend_line1)-1
%   hold on
%      line([xx(i,1)+v(i,2), xx(i,1)-v(i,2)],[yy(i,1)-v(i,1),yy(i,1)+v(i,1)])
%  end
% %  plot(xend_line1,yend_line1,'-k')
% 
% %  quiver(xstart,ystart,-dy,dx)
%   axis equal

robust=0;
active.ac=1;
setappdata(0, 'active', active);
%Calcula la interseccion


%t1
for i=1:length(xstart_line1)-1
    if isnan(xstart_line1(i,1)) | isnan(xend_line1(i,1)) | isnan(ystart_line1(i,1)) | isnan(yend_line1(i,1)) 
        xline1_int(:,i)=nan;
        yline1_int(:,i)=nan;
    else
        X11(:,i)=[xstart_line1(i,1);xend_line1(i,1)];
        Y22(:,i)=[ystart_line1(i,1);yend_line1(i,1)];
        %Find the intersection
        [xline1_int(1,i),yline1_int(1,i),~,~] = intersections(X11(:,i),Y22(:,i),xend,yend,robust);
       

%     figure(3)
%     plot(xline1_int(1,i),yline1_int(1,i),'or')
%     hold on
%     plot(xstart,ystart,'-r')
%     plot(xend,yend,'-g')
    end
end 
clear X11 Y22

   %Determinate cutoffs
    for i=1:length(xstart_line1)-1
        if i<5 | i>length(xstart_line1)-5
            Migra.cutoff(i)=nan;
        else
            if isnan(xline1_int(1,i))
                Migra.cutoff(i)=i;
            else
                Migra.cutoff(i)=nan;%no hay cutoff
            end
        end
    end
        
%t0
for i=1:length(xstart_line1)-1
    if isnan(xstart_line1(i,1)) | isnan(xend_line1(i,1)) | isnan(ystart_line1(i,1)) | isnan(yend_line1(i,1)) 
        xline1_int(:,i)=nan;
        yline1_int(:,i)=nan;
    else
        X11(:,i)=[xstart_line1(i,1);xend_line1(i,1)];
        Y22(:,i)=[ystart_line1(i,1);yend_line1(i,1)];
    [xline2_int(1,i),yline2_int(1,i),~,~] = intersections(X11(:,i),Y22(:,i),xstart,ystart,robust);
    end
end
clear X11 Y22


%%
%Calculate the distance

for i=1:length(xline1_int)
    
    Migra.MigrationSignal(i,1)=((xline1_int(i)-xline2_int(i))^2+(yline1_int(i)-yline2_int(i))^2)^0.5;
    
    if xline2_int(i)<xline1_int(i) & yline2_int(i)<yline1_int(i)
    Migra.Direction(i,1)=90-atand(((xline1_int(i)-xline2_int(i))^2)/((yline1_int(i)-yline2_int(i))^2));
    elseif xline2_int(i)>xline1_int(i) & yline2_int(i)<yline1_int(i)
    Migra.Direction(i,1)=180-atand(((xline1_int(i)-xline2_int(i))^2)/((yline1_int(i)-yline2_int(i))^2))-90;
    elseif xline2_int(i)>xline1_int(i) & yline2_int(i)>yline1_int(i)
        Migra.Direction(i,1)=270-atand(((xline1_int(i)-xline2_int(i))^2)/((yline1_int(i)-yline2_int(i))^2))-180;
    elseif xline2_int(i)<xline1_int(i) & yline2_int(i)>yline1_int(i)
        Migra.Direction(i,1)=360-atand(((xline1_int(i)-xline2_int(i))^2)/((yline1_int(i)-yline2_int(i))^2))-270;
    end
    
%     if i<5 & isnan(Migra.MigrationSignal(i,1))
%         Migra.MigrationSignal(i,:)=[];
%       %  Migra.Direction(i,:)=[];
%       elseif i>length(xline1_int)-5 & isnan(Migra.MigrationSignal(i,1))
%         Migra.MigrationSignal(i,:)=[];
%      %   Migra.Direction(i,:)=[];
%     end
%     
%     if isnan(Migra.MigrationSignal(i,1))
%    %     Migra.MigrationSignal(i,1)=0;
%         Migra.Direction(i,1)=0;
%     end
%     
end
Migra.MigrationSignal=Migra.MigrationSignal(1:length(Migra.Direction),1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Intersection lines and the determination of area
robust=0;
active.ac=0;
setappdata(0, 'active', active);

[ArMigra.xint_areat0,ArMigra.yint_areat0,iout0,jout0]=intersections(geovar{1}.equallySpacedX,geovar{1}.equallySpacedY,...
    geovar{2}.equallySpacedX,geovar{2}.equallySpacedY,robust);

[ArMigra.xint_areat1,ArMigra.yint_areat1,iout1,jout1]=intersections(geovar{2}.equallySpacedX,geovar{2}.equallySpacedY,...
    geovar{1}.equallySpacedX,geovar{1}.equallySpacedY,robust);

%Incopororate point to lines

%line t0

for t=1:length(ArMigra.xint_areat0)-1
    m=1;
    for r=1:length(geovar{1}.equallySpacedX)
        if r<iout0(t) & iout0(t)<r+1 %determina el primer nodo interseccion de una area
            lineax(m)=ArMigra.xint_areat0(t);
            lineay(m)=ArMigra.yint_areat0(t);
            distancia(m)=0;
            indice(m)=r;
            m=m+1;
        elseif iout0(t)<r & iout0(t+1)>r %nodos internos de una area
            lineax(m)=geovar{1}.equallySpacedX(r);
            lineay(m)=geovar{1}.equallySpacedY(r);
            distancia(m)=((lineax(m)-lineax(m-1))^2+(lineay(m)-lineay(m-1))^2)^0.5;
            indice(m)=r;
            m=m+1;
        elseif r>iout0(t+1) %nodo final del area
            lineax(m)=ArMigra.xint_areat0(t+1);
            lineay(m)=ArMigra.yint_areat0(t+1);
            indice(m)=r;
            distancia(m)=((lineax(m)-lineax(m-1))^2+(lineay(m)-lineay(m-1))^2)^0.5;
            m=m+1;
            break
        end
    end
    Migra.linet0X{t}.linea=lineax;
    Migra.linet0Y{t}.linea=lineay;
    %indice(indice==0)=[];
    Migra.Indext0{t}.ind=indice;
    Migra.distanciat0{t}=nansum(distancia);
    clear m lineax lineay distancia indice
end


%line t1
for t=1:length(ArMigra.xint_areat1)-1
    m=1;
    for r=1:length(geovar{2}.equallySpacedX)
        if r<iout1(t) & iout1(t)<r+1
            lineax(m)=ArMigra.xint_areat1(t);
            lineay(m)=ArMigra.yint_areat1(t);
            distancia(m)=0;
            indice(m)=r;
            m=m+1;
        elseif iout1(t)<r & iout1(t+1)>r
            lineax(m)=geovar{2}.equallySpacedX(r);
            lineay(m)=geovar{2}.equallySpacedY(r);
            distancia(m)=((lineax(m)-lineax(m-1))^2+(lineay(m)-lineay(m-1))^2)^0.5;
            indice(m)=r;
            m=m+1;
        elseif r>iout1(t+1) 
            lineax(m)=ArMigra.xint_areat1(t+1);
            lineay(m)=ArMigra.yint_areat1(t+1);
            distancia(m)=((lineax(m)-lineax(m-1))^2+(lineay(m)-lineay(m-1))^2)^0.5;
            indice(m)=r;
            break
        end
               
    end

    Migra.linet1X{t}.linea=lineax;
    Migra.linet1Y{t}.linea=lineay;
    Migra.Indext1{t}.ind=indice;
    %Migra.cutoff1{t}.cut=Migra.cutoff(indice);
    Migra.distanciat1{t}=nansum(distancia);
    clear m lineay lineax distancia indice
end


%Calculate area
for t=1:length(ArMigra.xint_areat1)-1
	Migra.areat0(t)=trapz(Migra.linet0X{t}.linea,Migra.linet0Y{t}.linea);
	Migra.areat1(t)=trapz(Migra.linet1X{t}.linea,Migra.linet1Y{t}.linea);
	Migra.areat0_t1(t)=abs(Migra.areat0(t)-Migra.areat1(t));
end

%Migration
for t=1:length(ArMigra.xint_areat1)-1
	Migra.AreaTot(t)=Migra.areat0_t1(t)/(Migra.distanciat0{t}+Migra.distanciat1{t});
% if length(Migra.Indext1{t}.ind)<3
% else
%     Migra.AreaTot(t)=nanmean(Migra.MigrationSignal(Migra.Indext1{t}.ind(1,2:end-1)));
% end
end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%go to wavelet analyzer
SIGLVL=0.95;
sel=2;%inflection Method
filter=0;
axest=[handles.wavel_axes];
Tools=2;%Migration tools

Migra.deltat=handles.year(2)-handles.year(1);

mStat_plotWavel(geovar{1},sel,SIGLVL,filter,axest,Tools,Migra)

%%%Plot
hwait = waitbar(0,'Plotting...','Name','MStaT ',...
         'CreateCancelBtn',...
            'setappdata(gcbf,''canceling'',1)');
setappdata(hwait,'canceling',0)

axes(handles.pictureReach)

    plot(xstart,ystart,'-b')%start
    hold on
    plot(xend,yend,'-k')
    plot(ArMigra.xint_areat0,ArMigra.yint_areat0,'or')
    legend('t0','t1','Intersection','Location','Best')
    grid on
    axis equal
    for t=2:length(xline1_int)
    %line([xstart(t,1) xline1_int(1,t)],[ystart(t,1) yline1_int(1,t)])
    %line([xstart_line1(t) xend_line1(t)],[ystart_line1(t) yend_line1(t)])
    %line([xline2_int(t) xline1_int(t)],[yline2_int(t) yline1_int(t)])

        D=[xline1_int(t) yline1_int(t)]-[xline2_int(t) yline2_int(t)];
        quiver(xline2_int(t),yline2_int(t),D(1),D(2),0,'filled','color','k','MarkerSize',10)
%      waitbar(((t/length(xline1_int))/50)/100,hwait); 
    end
% 
    xlabel('X');ylabel('Y')
    hold off
 
    waitbar(50/100,hwait);  
    
%Plot migration
axes(handles.signalvariation);

[hAx,hLine1,hLine2] = plotyy(geovar{1}.sResample(1:length(Migra.MigrationSignal),1),Migra.MigrationSignal/Migra.deltat,geovar{1}.sResample(1:length(Migra.MigrationSignal),1),Migra.Direction,'plot');
hold on

xlabel('Intrinsic Channel Lengths [m]');
% Define limits
    FileBed_dataMX=geovar{1}.sResample(1:length(Migra.MigrationSignal),1);
    xmin=min(FileBed_dataMX);     
    DeltaCentS=FileBed_dataMX(2,1)-FileBed_dataMX(1,1);  %units. 
    n=length((Migra.MigrationSignal/Migra.deltat)');
    xlim = [xmin,(n-1)*DeltaCentS+xmin];  % plotting range
    set(gca,'XLim',xlim(:));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

grid on
ylabel(hAx(1),'Migration/year [m/yr]') % left y-axis
ylabel(hAx(2),'Direction [�] ') % right y-axis

hLine1.LineStyle = '-';
hLine2.LineStyle = '--';

waitbar(100/100,hwait);
delete(hwait)