%function [x,r_plot,u_plot,et_plot,p_plot,t_plot,z_plot] = ...
%    DG_bgk1D_ARKv2_func(OUTTIME,TAU,nx,p,pp,stage,CFL,IT,bb,NV)
clear all
close all
tic
global A b c Pleg w wp NV nx p dx dt IT BC_type V VIS F gamma

name = 'ARKMBX64 P4RKs6w1000iv80.plt';
%GHNC       = 0;
%CFL        = 0.9;
OUTTIME     = 0.1;
TAU			= 0.001 %!RELAXATION TIME
IT          = 0;
%!maxwellian = 0., fermion = 1., boson = -1
nx = 64; % number of elements
p  = 4;			%polinomial degree
pp =p+1;
stage=6;
rk =stage;			%RK stage

BC_type = 0; % 0 No-flux; -1: reflecting
CFL=1/(2*p+1);
ratio=0.2;
% Filter Parameters
filter_order=4;
CutOff=1;
% bb=0: No plot; 1 assume continuous; 2 interval-by-interval
bb=0;

coeffi_RK
gamma=const_a_I(2,1);

NV = 80;
NVh=NV/2;
[GH,wp] = GaussHermite(NV); % for integrating range: -inf to inf
wp=wp';
V=-GH';
wp=wp.*exp(V.^2);

dx=1/nx;		%Stepwidth in space
amax=abs(V(1))

dt=CFL*dx*ratio/amax
% dt=min(dt,TAU)

I_plot=round(OUTTIME/dt/100);

tol=[1.d-6,1.d-6]*dx;
parms = [40,40,-.1,1];

%nt=round(OUTTIME/dt);
[xl,w]=gauleg(pp);
[Pleg]=legtable(xl,p);

% Initialize Variables
Init_Var

% Initialize Artificial Filter
filter_sigma=zeros(NV,nx,pp);
filter_tmp=filter_profile(p,filter_order, CutOff);
for i=1:pp
    filter_sigma(:,:,i)=filter_tmp(i);
end

% Initialize Plot-related Variables
[LG_grids_o,ValuesOFPolyNatGrids] = ZELEGL (No-1) ;
%[LG_weights_o] = WELEGL (N_pl,LG_grids_o,ValuesOFPolyNatGrids) ;

for i=1:No
    xloc=LG_grids_o(i);
    [PN,PD]=LPN(p,xloc);
    leg_tb_o(i,1:pp) = PN(1:pp);
end
Pleg_o=leg_tb_o';
for i=1:nx
    xi=(2*i-1)*dx/2;      %evaluating the function `func' at the quadrature points
    xo(i,:)=xi+LG_grids_o*dx/2;
end

% Initial State

% Case 1
RL=1.0;
UL=0.75;
PL=1.0;

ET=PL+0.5*RL*UL^2;
TL=4*ET/RL-2*UL^2;
ZL=RL/sqrt(pi*TL);

RR=0.125;
UR=0;
PR=0.1;

ET=PR+0.5*RR*UR^2;
TR=4*ET/RR-2*UR^2;
ZR=RR/sqrt(pi*TR);

% Case 2
% UL  = 0.;
% TL  = 4.38385;
% ZL  = 0.2253353;
% UR  = 0.;
% TR  = 8.972544;
% ZR  = 0.1204582;

%%%%%%%%%%%%%%  Transforming the initial condition to coefficients of Legendre Polinomials  %%%%%%%%%%%%%%%%%%%%
for i=1:nx
    xi=(2*i-1)*dx/2;      %evaluating the function `func' at the quadrature points
    x((i-1)*pp+1:i*pp)=xi+xl*dx/2;
    if(xi+xl(2)*dx/2 <= 0.5)
        U(i,:) = UL;
        T(i,:) = TL;
        Z(i,:) = ZL;
    else
        U(i,:) = UR;
        T(i,:) = TR;
        Z(i,:) = ZR;
    end
    
    for K = 1: NV
        for m=1:pp  %evaluating the function `func' at the quadrature points
            ffunc(m)  = 1/((exp((V(K)-U(i,m))^2/T(i,m))/Z(i,m)) + IT);
        end
        for j=0:p
            F(K,i,j+1)= sum (ffunc.*Pleg(j+1,:).*w)*(2*j+1)/2;
        end
    end
end

for i=1:nx
    Mtemp=zeros(NV,pp);
    for K=1:NV
        Mtemp(K,:)=F(K,i,:);
    end
    F_loc(:,:)=Mtemp*Pleg;
    for m=1:pp
        SR(i,:) = wp * F_loc;
        SU(i,m) = sum(wp.*F_loc(:,m)'.* V);
        SE(i,m) = sum(wp.*F_loc(:,m)'.* V.^2)/2;
        SAV(i,m)= sum(wp.*F_loc(:,m)'.* abs(V));
        
        R(i,m)    = SR(i,m);
        U(i,m)    = SU(i,m)/SR(i,m);
        ET(i,m)   = SE(i,m);
        AV(i,m)   = SAV(i,m);
        T(i,m)    = 4*ET(i,m)/R(i,m) - 2*U(i,m)^2;
        Z(i,m)    = R(i,m) / sqrt(pi* T(i,m));
    end
end

%Macrocopic Initial Condition
r_plot=reshape(R',nx*pp,1);
u_plot=reshape(U',nx*pp,1);
et_plot=reshape(ET',nx*pp,1);
p_plot=reshape(P',nx*pp,1);
t_plot=reshape(T',nx*pp,1);
z_plot=reshape(Z',nx*pp,1);

if bb==1
    r_plot=reshape(R',nx*pp,1);
    u_plot=reshape(U',nx*pp,1);
    scrsz = get(0,'ScreenSize');
    
    
    figure('Position',[1 scrsz(4)/8 scrsz(3)/2 scrsz(4)*3/4])
    wave_handleu=plot(x,u_plot,'-');
    axis([-0.2, 1.2, -0.5, 1.5]);
    
    figure('Position',[scrsz(3)/4 scrsz(4)/8 scrsz(3)/2 scrsz(4)*3/4])
    wave_handler=plot(x,r_plot,'-');
    
    axis([-0.2, 1.2, 0., 1.2]);
    xlabel('x'); ylabel('R(x,t)')
    drawnow
elseif bb==2
    for i=1:nx
        Mtemp=zeros(NV,pp);
        for K=1:NV
            Mtemp(K,:)=F(K,i,:);
        end
        Fo(:,:)=Mtemp*Pleg_o;
        for m=1:No
            SRo(i,:) = wp * Fo;
            SUo(i,m) = sum(wp.*Fo(:,m)'.* V);
            SEo(i,m) = sum(wp.*Fo(:,m)'.* V.^2)/2;
            
            Ro(i,m)    = SRo(i,m);
            Uo(i,m)    = SUo(i,m)/SRo(i,m);
            ETo(i,m)   = SEo(i,m);
        end
    end
    if (IT == 0)
        for i=1:nx
            for m=1:No
                To(i,m)    = 4*ETo(i,m)/Ro(i,m) - 2*Uo(i,m)^2;
                Zo(i,m)    = Ro(i,m) / sqrt(pi* To(i,m));
                Po(i,m) = ETo(i,m) - 0.5 * Ro(i,m) * Uo(i,m)^2;
                if To(i,m) <0
                    error('T is Negative')
                end
                if Po(i,m) <0
                    error('P is Negative')
                end
            end
        end
    elseif (IT==1)
        [Zo,To,Po]=ZTP_fun_F(nx,No,ETo,Ro,Uo)
    else
        [Zo,To,Po]=ZTP_fun_B(nx,No,ETo,Ro,Uo)
    end %if IT
    figure(1)
    plot(xo(1,:),Uo(1,:),'-');
    hold on
    for i=2:nx
        plot(xo(i,:),Uo(i,:),'-');
    end
    axis([-0.2, 1.2, -0.5, 0.5]);
    hold off
    figure(2)
    plot(xo(1,:),Ro(1,:),'-');
    hold on
    for i=2:nx
        plot(xo(i,:),Ro(i,:),'-');
    end
    axis([-0.2, 1.2, 0.2, 1.2]);
    hold off
    
    drawnow
else
    
end

pause(0.1)

% Generate Stiff-matrix, etc
for i=1:pp
    for j=1:pp
        if j>i && rem(j-i,2)==1
            A(i,j)=2;
        end
    end
    b(i)=(i-1/2)*2/dx;
    c(i)=(-1)^(i-1);
end

ITER  = 1;
TIME  = 0;
ISTOP = 0;
FC=zeros(pp,1);
FN=zeros(pp,1);
FB=zeros(pp,1);

while ISTOP ==0
    VIS(1:nx,1:pp) = TAU;
    
    TIME = TIME + dt;
    dtdx = dt/dx;
    
    if (TIME > OUTTIME)
        DTCFL = OUTTIME - (TIME - dt) ;
        TIME = OUTTIME;
        dt = DTCFL;
        dtdx = dt /dx;
        ISTOP = 1;
    end
    
    Fold=F;
    F_new=F;
    % RK Stages
    for l=1:rk
        
        if l==1 % Stage 1
            for i = 1:nx
                for K = 1:NV
                    for m=1:pp
                        FEQ(K,i,m)   = 1/((exp( (V(K)-U(i,m))^2 /T(i,m))/Z(i,m)) + IT );
                    end
                end
            end
            % Compute the Source Term
            for i=1:nx
                for K = 1: NV
                    FC(:)=F(K,i,:);
                    FB(:)=FEQ(K,i,:);
                    FC=(FC'*Pleg-FB')';
                    for j=0:p
                        FS(K,i,j+1)=sum (FC'.*Pleg(j+1,:).*w)*dx/2/VIS(i,j+1);
                    end
                end
                
            end
            for K=1:NVh
                % Right-going part
                if BC_type == 0
                    %BC no-flux
                    FC(:)=F(K,1,:);
                    FU=FC;
                    FR(:)=FS(K,1,:);
                    F_s(K,1,:,1)=( (-FR)' .* b);
                    F_ns(K,1,:,1)=( (V(K)*A'*FC -V(K)* sum(FC)+ V(K)* sum(FU'.* c) * c')' .* b);
                elseif BC_type == -1            %BC reflecting
                    FC(:)=F(K,1,:);
                    FU(:)=F(NV-K+1,1,:);
                    FR(:)=FS(K,1,:);
                    F_s(K,1,:,1)=( (-FR)' .* b);
                    F_ns(K,1,:,1)=( (V(K)*A'*FC -V(K)* sum(FC)+ V(K)* sum(FU'.* c) * c')' .* b);
                else
                end
                for i=2:nx
                    FU(:)=F(K,i-1,:);
                    FC(:)=F(K,i,:);
                    FR(:)=FS(K,i,:);
                    F_s(K,i,:,1)=( (-FR)' .* b);
                    F_ns(K,i,:,1)=( (V(K)*A'*FC -V(K)* sum(FC) +V(K)* sum(FU) * c')' .* b);
                end
                
                % Left-going part
                for i=1:nx-1
                    FU(:)=F(NVh+K,i+1,:);
                    FC(:)=F(NVh+K,i,:);
                    FR(:)=FS(NVh+K,i,:);
                    F_s(NVh+K,i,:,1)=( (-FR)' .* b);
                    F_ns(NVh+K,i,:,1)=( (-V(NVh+K)*A'*(-FC) -V(NVh+K)* sum(FU'.* c) + V(NVh+K)*sum(FC'.* c) * c')' .* b);
                end
                if BC_type == 0
                    %BC no-flux
                    FC(:)=F(NVh+K,nx,:);
                    FU=FC;
                    FR(:)=FS(NVh+K,nx,:);
                    F_s(NVh+K,nx,:,1)=( (-FR)' .* b);
                    F_ns(NVh+K,nx,:,1)=( (-V(NVh+K)*A'*(-FC) -V(NVh+K)* sum(FU) +V(NVh+K)* sum(FC'.*c) * c')' .* b);
                elseif BC_type == -1
                    %BC reflexting
                    FC(:)=F(NVh+K,nx,:);
                    FU(:)=F(NVh-K+1,nx,:);
                    FR(:)=FS(NVh+K,nx,:);
                    F_s(NVh+K,nx,:,1)=( (-FR)' .* b);
                    F_ns(NVh+K,nx,:,1)=( (-V(NVh+K)*A'*(-FC) -V(NVh+K)* sum(FU) +V(NVh+K)* sum(FC'.*c) * c')' .* b);
                end
            end % loop for NV
        else % Stage 2-6
            Fi=reshape(F_new,NV*nx*pp,1);
            %Solve Eq 43 in the manuscript
            [Fn, it_histg, ierr] = nsoli(Fi,'BGKimexL',tol,parms);
            %             [Fn, it_histg, ierr] = nsold(Fi,'BGKimexL',tol,parms);
            %             [Fn, it_histg, ierr] = brsola(Fi,'BGKimexL',tol,parms);
            
            F=reshape(Fn,NV,nx,pp);            
            %            F=F.*filter_sigma;
            
            % Compute R,U,ET at every quadrature points
            for i=1:nx
                Mtemp=zeros(NV,pp);
                for K=1:NV
                    Mtemp(K,:)=F(K,i,:);
                end
                % Evaluate f at every quadrature points
                F_loc(:,:)=Mtemp*Pleg;
                for m=1:pp
                    SR(i,:) = wp * F_loc;
                    SU(i,m) = sum(wp.*F_loc(:,m)'.* V);
                    SE(i,m) = sum(wp.*F_loc(:,m)'.* V.^2)/2;
                    SAV(i,m)= sum(wp.*F_loc(:,m)'.* abs(V));
                    
                    R(i,m)    = SR(i,m);
                    U(i,m)    = SU(i,m)/SR(i,m);
                    ET(i,m)   = SE(i,m);
                    AV(i,m)   = SAV(i,m);
                end
            end
            
            if (IT == 0)
                for i=1:nx
                    for m=1:pp
                        T(i,m)    = 4*ET(i,m)/R(i,m) - 2*U(i,m)^2;
                        Z(i,m)    = R(i,m) / sqrt(pi* T(i,m));
                        P(i,m) = ET(i,m) - 0.5 * R(i,m) * U(i,m)^2;
                        if T(i,m) <0
                            error('T is Negative')
                        end
                        if P(i,m) <0
                            error('P is Negative')
                        end
                    end
                end
            elseif (IT==1)
                [Z,T,P]=ZTP_fun_F(nx,pp,ET,R,U);
            else
                [Z,T,P]=ZTP_fun_B(nx,pp,ET,R,U);
            end %if IT
            
            for i = 1:nx
                for K = 1:NV
                    for m=1:pp
                        FEQ(K,i,m)   = 1/((exp( (V(K)-U(i,m))^2 /T(i,m))/Z(i,m)) + IT );
                    end
                end
            end
            % Source Term
            for i=1:nx
                for K = 1: NV
                    FC(:)=F(K,i,:);
                    FB(:)=FEQ(K,i,:);
                    FC=(FC'*Pleg-FB')';
                    
                    for j=0:p
                        FS(K,i,j+1)=sum (FC'.*Pleg(j+1,:).*w)*dx/2/VIS(i,j+1);
                    end
                end
            end
            % DG Method
            for K=1:NVh  
                % Right-going part
                if BC_type == 0
                    %BC no-flux
                    FC(:)=F(K,1,:);
                    FU=FC;
                    FR(:)=FS(K,1,:);
                    %F_ns(K,1,:,l)=( (V(K)*A'*FC -V(K)* sum(FC)+ V(K)* sum(FU'.* c) * c'-FR)' .* b);
                    F_s(K,1,:,l)=( (-FR)' .* b);
                    F_ns(K,1,:,l)=( (V(K)*A'*FC -V(K)* sum(FC)+ V(K)* sum(FU'.* c) * c')' .* b);
                elseif BC_type == -1            %BC reflecting
                    FC(:)=F(K,1,:);
                    FU(:)=F(NV-K+1,1,:);
                    FR(:)=FS(K,1,:);
                    %F_ns(K,1,:,l)=( (V(K)*A'*FC -V(K)* sum(FC)+ V(K)* sum(FU'.* c) * c'-FR)' .* b);
                    F_s(K,1,:,l)=( (-FR)' .* b);
                    F_ns(K,1,:,l)=( (V(K)*A'*FC -V(K)* sum(FC)+ V(K)* sum(FU'.* c) * c')' .* b);
                else
                end
                for i=2:nx
                    FU(:)=F(K,i-1,:);
                    FC(:)=F(K,i,:);
                    FR(:)=FS(K,i,:);
                    F_s(K,i,:,l)=( (-FR)' .* b);
                    F_ns(K,i,:,l)=( (V(K)*A'*FC -V(K)* sum(FC) +V(K)* sum(FU) * c')' .* b);
                end
                 % Left-going part
                for i=1:nx-1
                    FU(:)=F(NVh+K,i+1,:);
                    FC(:)=F(NVh+K,i,:);
                    FR(:)=FS(NVh+K,i,:);
                    F_s(NVh+K,i,:,l)=( (-FR)' .* b);
                    F_ns(NVh+K,i,:,l)=( (-V(NVh+K)*A'*(-FC) -V(NVh+K)* sum(FU'.* c) + V(NVh+K)*sum(FC'.* c) * c')' .* b);
                end
                if BC_type == 0
                    %BC no-flux
                    FC(:)=F(NVh+K,nx,:);
                    FU=FC;
                    FR(:)=FS(NVh+K,nx,:);
                    F_s(NVh+K,nx,:,l)=( (-FR)' .* b);
                    F_ns(NVh+K,nx,:,l)=( (-V(NVh+K)*A'*(-FC) -V(NVh+K)* sum(FU) +V(NVh+K)* sum(FC'.*c) * c')' .* b);
                elseif BC_type == -1
                    %BC reflexting
                    FC(:)=F(NVh+K,nx,:);
                    FU(:)=F(NVh-K+1,nx,:);
                    FR(:)=FS(NVh+K,nx,:);
                    F_s(NVh+K,nx,:,l)=( (-FR)' .* b);
                    F_ns(NVh+K,nx,:,l)=( (-V(NVh+K)*A'*(-FC) -V(NVh+K)* sum(FU) +V(NVh+K)* sum(FC'.*c) * c')' .* b);
                end
            end % loop for NV
        end
        
        if l<stage
            F_new=F_new+ dt*const_b(l)*(F_s(:,:,:,l)+F_ns(:,:,:,l));
            F=Fold;
            for j=1:l %u_alt=Un+Xi
                F = F + dt*(const_a_I(l+1,j)*F_s(:,:,:,j) + const_a_E(l+1,j)*F_ns(:,:,:,j));
            end
            % Compute R,U,ET at every quadrature points
            for i=1:nx
                Mtemp=zeros(NV,pp);
                for K=1:NV
                    Mtemp(K,:)=F(K,i,:);
                end
                F_loc(:,:)=Mtemp*Pleg;
                for m=1:pp
                    SR(i,:) = wp * F_loc;
                    SU(i,m) = sum(wp.*F_loc(:,m)'.* V);
                    SE(i,m) = sum(wp.*F_loc(:,m)'.* V.^2)/2;
                    SAV(i,m)= sum(wp.*F_loc(:,m)'.* abs(V));
                    
                    R(i,m)    = SR(i,m);
                    U(i,m)    = SU(i,m)/SR(i,m);
                    ET(i,m)   = SE(i,m);
                    AV(i,m)   = SAV(i,m);
                end
            end
            
            if (IT == 0)
                for i=1:nx
                    for m=1:pp
                        T(i,m)    = 4*ET(i,m)/R(i,m) - 2*U(i,m)^2;
                        Z(i,m)    = R(i,m) / sqrt(pi* T(i,m));
                        P(i,m) = ET(i,m) - 0.5 * R(i,m) * U(i,m)^2;
                        if T(i,m) <0
                            error('T is Negative')
                        end
                        if P(i,m) <0
                            error('P is Negative')
                        end
                    end
                end
            elseif (IT==1)
                [Z,T,P]=ZTP_fun_F(nx,pp,ET,R,U);
            else
                [Z,T,P]=ZTP_fun_B(nx,pp,ET,R,U);
            end %if IT
            
        else % Final Stage Eq 42
            F_new=F_new+ dt*const_b(l)*(F_s(:,:,:,l)+F_ns(:,:,:,l));
            
        end
    end % RK
     
    % Filter
    %F=F_new.*filter_sigma;    
    % Un-comment the line above and comment the line below to impose the
    % artificial filter
    F=F_new;  % No-Filter
    
    for i=1:nx
        Mtemp=zeros(NV,pp);
        for K=1:NV
            Mtemp(K,:)=F(K,i,:);
        end
        % Evaluate f at every quadrature points
        F_loc(:,:)=Mtemp*Pleg;
        for m=1:pp
            SR(i,:) = wp * F_loc;
            SU(i,m) = sum(wp.*F_loc(:,m)'.* V);
            SE(i,m) = sum(wp.*F_loc(:,m)'.* V.^2)/2;
            SAV(i,m)= sum(wp.*F_loc(:,m)'.* abs(V));
            
            R(i,m)    = SR(i,m);
            U(i,m)    = SU(i,m)/SR(i,m);
            ET(i,m)   = SE(i,m);
            AV(i,m)   = SAV(i,m);
        end
    end
    
    if (IT == 0)
        for i=1:nx
            for m=1:pp
                T(i,m)    = 4*ET(i,m)/R(i,m) - 2*U(i,m)^2;
                Z(i,m)    = R(i,m) / sqrt(pi* T(i,m));
                P(i,m) = ET(i,m) - 0.5 * R(i,m) * U(i,m)^2;
                if T(i,m) <0
                    error('T is Negative')
                end
                if P(i,m) <0
                    error('P is Negative')
                end
            end
        end
    elseif (IT==1)
        [Z,T,P]=ZTP_fun_F(nx,pp,ET,R,U);
    else
        [Z,T,P]=ZTP_fun_B(nx,pp,ET,R,U);
    end %if IT
    if mod(ITER,I_plot)==0
        if bb==1
            r_plot=reshape(R',nx*pp,1);
            u_plot=reshape(U',nx*pp,1);
            
            set(wave_handleu,'YData',u_plot);
            set(wave_handler,'YData',r_plot);
            drawnow
        elseif bb==2
            %Output
            for i=1:nx
                Mtemp=zeros(NV,pp);
                for K=1:NV
                    Mtemp(K,:)=F(K,i,:);
                end
                Fo(:,:)=Mtemp*Pleg_o;
                for m=1:No
                    SRo(i,:) = wp * Fo;
                    SUo(i,m) = sum(wp.*Fo(:,m)'.* V);
                    SEo(i,m) = sum(wp.*Fo(:,m)'.* V.^2)/2;
                    
                    Ro(i,m)    = SRo(i,m);
                    Uo(i,m)    = SUo(i,m)/SRo(i,m);
                    ETo(i,m)   = SEo(i,m);
                end
            end
            if (IT == 0)
                for i=1:nx
                    for m=1:No
                        To(i,m)    = 4*ETo(i,m)/Ro(i,m) - 2*Uo(i,m)^2;
                        Zo(i,m)    = Ro(i,m) / sqrt(pi* To(i,m));
                        Po(i,m) = ETo(i,m) - 0.5 * Ro(i,m) * Uo(i,m)^2;
                        if To(i,m) <0
                            error('T is Negative')
                        end
                        if Po(i,m) <0
                            error('P is Negative')
                        end
                    end
                end
            elseif (IT==1)
                [Zo,To,Po]=ZTP_fun_F(nx,No,ETo,Ro,Uo);
            else
                [Zo,To,Po]=ZTP_fun_B(nx,No,ETo,Ro,Uo);
            end %if IT
            figure(1)
            plot(xo(1,:),Uo(1,:),'-');
            hold on
            for i=2:nx
                plot(xo(i,:),Uo(i,:),'-');
            end
            axis([-0.2, 1.2, -0.5, 0.5]);
            hold off
            figure(2)
            plot(xo(1,:),Ro(1,:),'-');
            hold on
            for i=2:nx
                plot(xo(i,:),Ro(i,:),'-');
            end
            axis([-0.2, 1.2, 0.2, 1.2]);
            hold off
            
            drawnow
        else
        end
    end
    %fprintf('1X ELAPSED TIME: %f7.4,4 DENSITY AT X=4.0,Y=5.: %f7.4\n', TIME, R(NXP1/2))
        
    r_plot=reshape(R',nx*pp,1);
    u_plot=reshape(U',nx*pp,1);
    et_plot=reshape(ET',nx*pp,1);
    p_plot=reshape(P',nx*pp,1);
    t_plot=reshape(T',nx*pp,1);
    z_plot=reshape(Z',nx*pp,1);
    
    ITER = ITER + 1;
end

%Output
if bb ~= 1
    for i=1:nx
        Mtemp=zeros(NV,pp);
        for K=1:NV
            Mtemp(K,:)=F(K,i,:);
        end
        Fo(:,:)=Mtemp*Pleg_o;
        for m=1:No
            SRo(i,:) = wp * Fo;
            SUo(i,m) = sum(wp.*Fo(:,m)'.* V);
            SEo(i,m) = sum(wp.*Fo(:,m)'.* V.^2)/2;
            
            Ro(i,m)    = SRo(i,m);
            Uo(i,m)    = SUo(i,m)/SRo(i,m);
            ETo(i,m)   = SEo(i,m);
        end
    end
    
    if (IT == 0)
        for i=1:nx
            for m=1:No
                To(i,m)    = 4*ETo(i,m)/Ro(i,m) - 2*Uo(i,m)^2;
                Zo(i,m)    = Ro(i,m) / sqrt(pi* To(i,m));
                Po(i,m) = ETo(i,m) - 0.5 * Ro(i,m) * Uo(i,m)^2;
                if To(i,m) <0
                    error('T is Negative')
                end
                if Po(i,m) <0
                    error('P is Negative')
                end
            end
        end
    elseif (IT==1)
        [Zo,To,Po]=ZTP_fun_F(nx,No,ETo,Ro,Uo);
    else
        [Zo,To,Po]=ZTP_fun_B(nx,No,ETo,Ro,Uo);
    end %if IT
    
%     r_plot=reshape(Ro',nx*pp,1);
%     u_plot=reshape(Uo',nx*pp,1);
%     et_plot=reshape(ETo',nx*pp,1);
%     p_plot=reshape(Po',nx*pp,1);
%     t_plot=reshape(To',nx*pp,1);
%     z_plot=reshape(Zo',nx*pp,1);    
    
%     figure(1)
%     plot(xo(1,:),Uo(1,:),'-');
%     hold on
%     for i=2:nx
%         plot(xo(i,:),Uo(i,:),'-');
%     end
%     axis([-0.2, 1.2, -0.5, .5]);
%     hold off
%     figure(2)
%     plot(xo(1,:),Ro(1,:),'-');
%     hold on
%     for i=2:nx
%         plot(xo(i,:),Ro(i,:),'-');
%     end
%     axis([-0.2, 1.2, 0.2, 1.2]);
%     hold off
end
toc

%% Write results to tecplot

    nx = length(x);
    % Open file
    file = fopen(name,'w');
    % 'file' gets the handel for the file "case.plt".
    % 'w' specifies that it will be written.
    % similarly 'r' is for reading and 'a' for appending.
    
    fprintf(file, 'TITLE = "%s"\n','ARKv2');
    fprintf(file, 'VARIABLES = "x" "Density" "Velocity in x" "Energy" "Pressure" "Temperature" "Fugacity"\n');
    fprintf(file, 'ZONE T = "Final Time %0.2f"\n', TIME);
    fprintf(file, 'I = %d, J = 1, K = 1, F = POINT\n\n', nx);
    
    for j = 1:nx
        fprintf(file, '%f\t%f\t%f\t%f\t%f\t%f\t%f\t\n', ...
            x(j),r_plot(j),u_plot(j),et_plot(j),p_plot(j),t_plot(j),z_plot(j));
    end
    % Close file
    fclose(file);
    
%% if everything is ok then, tell me:
fprintf('All Results have been succesfully saved!\n')