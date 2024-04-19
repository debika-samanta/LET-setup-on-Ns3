/*
 * Copyright (c) 2011-2018 Centre Tecnologic de Telecomunicacions de Catalunya (CTTC)
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation;
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * Authors:
 *   Jaume Nin <jaume.nin@cttc.cat>
 *   Manuel Requena <manuel.requena@cttc.es>
 */

#include "ns3/applications-module.h"
#include "ns3/config-store-module.h"
#include "ns3/core-module.h"
#include "ns3/internet-module.h"
#include "ns3/lte-module.h"
#include "ns3/mobility-module.h"
#include "ns3/point-to-point-module.h"
#include "ns3/applications-module.h"
#include "ns3/config-store.h"
#include "ns3/core-module.h"
#include "ns3/internet-module.h"
#include "ns3/log.h"
#include "ns3/lte-module.h"
#include "ns3/mobility-module.h"
#include "ns3/network-module.h"
#include "ns3/point-to-point-epc-helper.h"
#include "ns3/point-to-point-module.h"
#include "ns3/spectrum-module.h"
#include <ns3/buildings-helper.h>
// #include "ns3/gtk-config-store.h"

using namespace ns3;

/**
 * Simulation script for LTE+EPC, which sets up four eNBs at the vertices of a
 * square with given inter-eNB distance. Five UEs executing a random 2d walk are
 * attached to each of the eNBs to simulate handover. A UDP flow is set up for
 * each eNB to the EPC.
*/

NS_LOG_COMPONENT_DEFINE("LenaSimpleEpc");

int
main(int argc, char* argv[])
{
    // Total simulation time
    Time simTime = Seconds(10);
    // Inter-distance between eNBs
    double distance = 1000.0;
    double dist_by_2 = distance/2;

    // Number of eNBs
    uint16_t numEnbNodes = 4;
    // Number of UEs per eNB
    uint16_t numUeNodesPerEnb = 5;
    std::string schedulerType = "ns3::PfFfMacScheduler";
    double speed = 0;
    uint16_t RngRun = 0;
    int fullBufferFlag = 0;
    int generateRem = 0;

    // Command line arguments
    CommandLine cmd(__FILE__);
    cmd.AddValue("schedulerType", "Type of MAC scheduler to be used", schedulerType);
    cmd.AddValue("speed", "Speed at which UEs are moving (m/s)", speed);
    cmd.AddValue("RngRun", "Run number", RngRun);
    cmd.AddValue("fullBufferFlag", "Flag to simulate full buffer situation", fullBufferFlag);
    cmd.AddValue("generateRem", "Flag to generate REM", generateRem);
    cmd.Parse(argc, argv);

    ConfigStore inputConfig;
    inputConfig.ConfigureDefaults();

    // parse again so you can override default values from the command line
    cmd.Parse(argc, argv);

    // Set inter-packet interval based on scenario
    Time interPacketInterval = MilliSeconds(fullBufferFlag?1:10);

    // Set RNG seeds for reproducibility
    RngSeedManager::SetSeed(18 + RngRun);
    RngSeedManager::SetRun(RngRun);

    Ptr<ConstantRandomVariable> speed_rv = CreateObject<ConstantRandomVariable>();
    speed_rv->SetAttribute("Constant", DoubleValue(speed));

    // Set Tx Power of the eNBs
    Config::SetDefault("ns3::LteEnbPhy::TxPower", DoubleValue(30.0));

    Ptr<LteHelper> lteHelper = CreateObject<LteHelper>();
    lteHelper->SetEnbDeviceAttribute("DlBandwidth", UintegerValue(50));
    lteHelper->SetEnbDeviceAttribute("UlBandwidth", UintegerValue(50));

    Ptr<PointToPointEpcHelper> epcHelper = CreateObject<PointToPointEpcHelper>();
    lteHelper->SetEpcHelper(epcHelper);

    // Set MAC scheduler type
    lteHelper->SetSchedulerType(schedulerType);

    Ptr<Node> pgw = epcHelper->GetPgwNode();

    // Create a single RemoteHost
    NodeContainer remoteHostContainer;
    remoteHostContainer.Create(1);
    Ptr<Node> remoteHost = remoteHostContainer.Get(0);
    InternetStackHelper internet;
    internet.Install(remoteHostContainer);

    // Create the Internet
    PointToPointHelper p2ph;
    p2ph.SetDeviceAttribute("DataRate", DataRateValue(DataRate("1Gb/s")));
    p2ph.SetDeviceAttribute("Mtu", UintegerValue(1500));
    if (fullBufferFlag) p2ph.SetChannelAttribute("Delay", TimeValue(MilliSeconds(1)));
    else p2ph.SetChannelAttribute("Delay", TimeValue(MilliSeconds(10)));
    NetDeviceContainer internetDevices = p2ph.Install(pgw, remoteHost);
    Ipv4AddressHelper ipv4h;
    ipv4h.SetBase("1.0.0.0", "255.0.0.0");
    Ipv4InterfaceContainer internetIpIfaces = ipv4h.Assign(internetDevices);
    // interface 0 is localhost, 1 is the p2p device
    // Ipv4Address remoteHostAddr = internetIpIfaces.GetAddress(1);

    Ipv4StaticRoutingHelper ipv4RoutingHelper;
    Ptr<Ipv4StaticRouting> remoteHostStaticRouting =
        ipv4RoutingHelper.GetStaticRouting(remoteHost->GetObject<Ipv4>());
    remoteHostStaticRouting->AddNetworkRouteTo(Ipv4Address("7.0.0.0"), Ipv4Mask("255.0.0.0"), 1);

    NodeContainer enbNodes;
    enbNodes.Create(numEnbNodes);

    // Install Mobility Model for eNodeBs
    Ptr<ListPositionAllocator> positionAlloc = CreateObject<ListPositionAllocator>();
    positionAlloc->Add(Vector(dist_by_2, dist_by_2, 0));
    positionAlloc->Add(Vector(dist_by_2, -dist_by_2, 0));
    positionAlloc->Add(Vector(-dist_by_2, dist_by_2, 0));
    positionAlloc->Add(Vector(-dist_by_2, -dist_by_2, 0));
    MobilityHelper mobility;
    mobility.SetMobilityModel("ns3::ConstantPositionMobilityModel");
    mobility.SetPositionAllocator(positionAlloc);
    mobility.Install(enbNodes);
    NetDeviceContainer enbLteDevs = lteHelper->InstallEnbDevice(enbNodes);

    // Download and upload ports for applications
    uint16_t dlPort = 1100;
    for (int i = 0; i < 4; i++)
    {
        ApplicationContainer clientApps;
        ApplicationContainer serverApps;
        double x = dist_by_2*((i&1)?1:-1);
        double y = dist_by_2*((i&2)?1:-1);

        NodeContainer ueNodes;
        ueNodes.Create(numUeNodesPerEnb);

        MobilityHelper ue_mobility;
        ue_mobility.SetMobilityModel("ns3::RandomWalk2dMobilityModel",
                                     "Mode",
                                     StringValue("Time"),
                                     "Speed",
                                     PointerValue(speed_rv),
                                     "Bounds",
                                     RectangleValue(Rectangle(-distance, distance, -distance, distance)));
        ue_mobility.SetPositionAllocator("ns3::UniformDiscPositionAllocator",
                                         "X", DoubleValue(x),
                                         "Y", DoubleValue(y),
                                         "rho", DoubleValue(dist_by_2));
        ue_mobility.Install(ueNodes);

        // Install LTE Devices to the nodes
        NetDeviceContainer ueLteDevs = lteHelper->InstallUeDevice(ueNodes);

        // Install the IP stack on the UEs
        internet.Install(ueNodes);
        Ipv4InterfaceContainer ueIpIface;
        ueIpIface = epcHelper->AssignUeIpv4Address(NetDeviceContainer(ueLteDevs));
        // Assign IP address to UEs, and install applications
        for (uint32_t u = 0; u < ueNodes.GetN(); ++u)
        {
            Ptr<Node> ueNode = ueNodes.Get(u);
            // Set the default gateway for the UE
            Ptr<Ipv4StaticRouting> ueStaticRouting =
                ipv4RoutingHelper.GetStaticRouting(ueNode->GetObject<Ipv4>());
            ueStaticRouting->SetDefaultRoute(epcHelper->GetUeDefaultGatewayAddress(), 1);
        }

        lteHelper->Attach(ueLteDevs);

        // Install and start applications on UEs and remote host
        for (uint32_t u = 0; u < ueNodes.GetN(); ++u)
        {
            ++dlPort;
            PacketSinkHelper dlPacketSinkHelper("ns3::UdpSocketFactory",
                                                InetSocketAddress(Ipv4Address::GetAny(), dlPort));
            serverApps.Add(dlPacketSinkHelper.Install(ueNodes.Get(u)));

            UdpClientHelper dlClient(ueIpIface.GetAddress(u), dlPort);
            dlClient.SetAttribute("Interval", TimeValue(interPacketInterval));
            dlClient.SetAttribute("MaxPackets", UintegerValue(1000000));
            clientApps.Add(dlClient.Install(remoteHost));
        }
        serverApps.Start(MilliSeconds(500));
        clientApps.Start(MilliSeconds(500));
    }

    lteHelper->EnableRlcTraces();
    lteHelper->EnableDlPhyTraces();
    // Uncomment to enable PCAP tracing
    // p2ph.EnablePcapAll("lena-simple-epc");
    
    Simulator::Stop(simTime);
    Ptr<RadioEnvironmentMapHelper> remHelper = CreateObject<RadioEnvironmentMapHelper>();

    remHelper->SetAttribute("Channel", PointerValue(lteHelper->GetDownlinkSpectrumChannel()));
    remHelper->SetAttribute("OutputFile", StringValue("rem.out"));
    remHelper->SetAttribute("XMin", DoubleValue(-distance));
    remHelper->SetAttribute("XMax", DoubleValue(distance));
    remHelper->SetAttribute("XRes", UintegerValue(501));
    remHelper->SetAttribute("YMin", DoubleValue(-distance));
    remHelper->SetAttribute("YMax", DoubleValue(distance));
    remHelper->SetAttribute("YRes", UintegerValue(501));
    remHelper->SetAttribute("Z", DoubleValue(0.0));
    // Deploy the REM if generateRem flag is set, as simulation will stop right after the REM has been generated
    if (generateRem) remHelper->Install();

    Simulator::Run();

    /*GtkConfigStore config;
    config.ConfigureAttributes();*/

    Simulator::Destroy();
    return 0;
}
