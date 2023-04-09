import {
  Box, Center, Flex, Icon, Button, VStack, Checkbox, Text, HStack, Imageimport,
  Card, CardHeader, CardBody, CardFooter, SimpleGrid, Heading
} from '@chakra-ui/react';
import { FaExchangeAlt } from "react-icons/fa";
import { useAccount, useProvider, useSigner, useContractEvent } from 'wagmi'
import { getNetwork } from '@wagmi/core'
import { useState, useEffect } from 'react'
import { ethers } from 'ethers'
import hodlUpHubfromContract from "../../src/contracts/HodlUpHub.json"
import ERC20Contract from "../../src/contracts/ERC20.json"
import wagmi from 'wagmi';

function BoxManagePositions(props) {
  const [myContract, setMyContract] = useState("");
  const [myAddress, setMyAddress] = useState("0x");
  const { data: signer } = useSigner();
  const provider = useProvider();
  const { address, isConnecting, isDisconnected } = useAccount();
  const [createdPositions, setCreatedPositions] = useState([]);

  const loadContract = async () => {

    const { chain } = getNetwork();
    //const contractAddress = hodlUpHubfromContract.networks[137].address;
    const hodlUpContractAddress = hodlUpHubfromContract.networks[chain.id == 1337 ? 137 : chain.id].address;
    const hodlUpContractABI = hodlUpHubfromContract.abi;
    const hodlUpContract = new ethers.Contract(hodlUpContractAddress, hodlUpContractABI, provider);
    //console.log(signer);
    // Stockez le contrat dans l'état du composant --chain.chainId=
    setMyContract(hodlUpContract);
    // setMyAddress(address);

  };

  useEffect(() => {
    loadContract();
    getCreatedPositions();
  }, [useProvider, signer, useAccount, provider]);




  const getCreatedPositions = async () => {

    if (!myContract) {
      console.log("pas de contrat");
      return;
    }

    const eventFilter = myContract.filters.PositionCreated(address, null, null);
    if (!eventFilter) {
      console.log("pas de filter");
      return;
    }
    const events = await myContract.queryFilter(eventFilter, 41297612, 'latest');
    if (!eventFilter) {
      console.log("pas d'event'");
      return;
    }

    const positions = []; // tableau temporaire pour stocker les positions
    for (const event of events) {
      console.log("COINCOIN");
      const index = Number((event.args[1])._hex);
      console.log("index: ", index);
      const position = await myContract.getPosition(index, { from: address });
      console.log("AAAAAAposition: ", position);
      positions.push(position); // Ajoute la position au tableau temporaire
    }
    setCreatedPositions(positions);
  };


  useContractEvent({
    address: myContract.address,
    abi: hodlUpHubfromContract.abi,
    eventName: 'PositionCreated',
    listener(sender, id, date) {
      console.log("!!!sender: ", sender);
      console.log("!!!id: ", id);
      console.log("!!!date: ", date);
      getCreatedPositions();
    },
  })

  //console.log(events);
  return (

    <Box className="box_management_position" p="5" borderWidth="1px" position="relative">
      <Flex align="baseline" mt={2}>
        <Box overflowX="auto" width="100%" overflowY="hidden">
          <SimpleGrid columns={{ sm: 1, md: 2 }} spacing={4} h="430px" overflow="auto">
            {createdPositions.map((card) => (
              <Card key={card.id} color="white" bg="#132A3A" h="300px" w="220px">
                <CardHeader h="4px">
                  <Heading size="sm" fontSize="14px">{card.name}</Heading>
                </CardHeader>
                <CardBody>
                  <Text>Recurrence: {card.interval / 3600} days</Text>
                </CardBody>
                <CardFooter justifyContent="center">
                  <Button backgroundColor="#28DA98" color="black" fontWeight="bold" size="sm">
                    Pause
                  </Button>
                  <Button marginLeft={2} backgroundColor="#ffaf8c" color="black" fontWeight="bold" size="sm">
                    Close
                  </Button>
                </CardFooter>
              </Card>
            ))}
          </SimpleGrid>
        </Box>
      </Flex>
    </Box>
  );
}

export default BoxManagePositions;