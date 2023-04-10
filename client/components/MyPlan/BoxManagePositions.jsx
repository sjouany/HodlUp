import {
  Box, Flex, Button, Text,
  Card, CardHeader, CardBody, CardFooter, SimpleGrid, Heading
} from '@chakra-ui/react';
import { useAccount, useProvider, useSigner, useContractEvent } from 'wagmi'
import { getNetwork } from '@wagmi/core'
import { useState, useEffect } from 'react'
import { ethers } from 'ethers'
import hodlUpHubfromContract from "../../src/contracts/HodlUpHub.json"
import ERC20Contract from "../../src/contracts/ERC20.json"
import wagmi from 'wagmi';
const mappings = require("../../src/constant/constant.js");

function BoxManagePositions(props) {
  const [myContract, setMyContract] = useState("");
  const [myContractToUpdate, setMyContractToUpdate] = useState("");
  const [myAddress, setMyAddress] = useState("0x");
  const { data: signer } = useSigner();
  const provider = useProvider();
  const { address, isConnecting, isDisconnected } = useAccount();
  const [createdPositions, setCreatedPositions] = useState([]);

  const loadContract = async () => {

    const { chain } = getNetwork();
    const hodlUpContractAddress = hodlUpHubfromContract.networks[chain.id == 1337 ? 137 : chain.id].address;
    const hodlUpContractABI = hodlUpHubfromContract.abi;
    const hodlUpContract = new ethers.Contract(hodlUpContractAddress, hodlUpContractABI, provider);
    const hodlUpContractToUpdate = new ethers.Contract(hodlUpContractAddress, hodlUpContractABI, signer);
    setMyContract(hodlUpContract);
    setMyContractToUpdate(hodlUpContractToUpdate);
  };

  useEffect(() => {
    loadContract();
    getCreatedPositions();
  }, [useProvider, signer, useAccount, provider]);

  function getDate(bigNumber) {
    const timestamp = parseInt(bigNumber);
    if (timestamp > 0) return (new Date(timestamp * 1000).toLocaleDateString());
    return "";
  };

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
    const events = await myContract.queryFilter(eventFilter, 41365681, 'latest');
    if (!eventFilter) {
      console.log("pas d'event'");
      return;
    }
    const positions = []; // tableau temporaire pour stocker les positions
    let index = 0;
    for (const event of events) {
      console.log("COINCOIN");
      console.log("index: ", index);
      try {
        const position = await myContract.getPosition(index, { from: address });
        const positionToInsert = {
          id: index,
          name: position.name,
          totalAmountToSwap: parseInt(position.totalAmountToSwap),
          interval: parseInt(position.interval) / (3600),
          SwappedFromBalance: parseInt(position.SwappedFromBalance),
          SwappedToBalance: parseInt(position.SwappedToBalance),
          amountPerSwap: parseInt(position.amountPerSwap),
          lastPurchaseTimestamp: getDate(position.lastPurchaseTimestamp._hex),
          createdTimestamp: getDate(position.createdTimestamp._hex),
          status: position.status
        }

        console.log("AAAAAAposition: ", positionToInsert);
        positions.push(positionToInsert);
        index++; // Ajoute la position au tableau temporaire
      }
      catch {
        console.log("proposition not found. it shouled be archived")
      }
    }
    setCreatedPositions(positions);
  };

  useContractEvent({
    address: myContract.address,
    abi: hodlUpHubfromContract.abi,
    eventName: 'PositionCreated',
    listener(sender, id, date) {
      getCreatedPositions();
    },
  })

  const setPositionStatus = async (id, status) => {
    const transaction = await myContractToUpdate.setPositionStatus(id, status);
  };

  const closePosition = async (id) => {
    const transaction = await myContractToUpdate.closePosition(id);
  };

  const handlePause = async (cardId, cardStatus) => {
    if (cardStatus === 1 || cardStatus === 0) {
      await setPositionStatus(cardId, cardStatus === 1 ? 0 : cardStatus === 0 ? 1 : cardStatus);
    }
    getCreatedPositions();
  };

  const handleClose = async (cardId, cardStatus) => {
    if (cardStatus === 1 || cardStatus === 0) {
      await closePosition(cardId);
    }
    getCreatedPositions();
  };

  //console.log(events);
  return (

    <Box className="box_management_position" p="5" borderWidth="1px" position="relative">
      <Flex align="baseline" mt={2}>
        <Box overflowX="auto" width="100%" overflowY="hidden">
          <SimpleGrid columns={{ sm: 1, md: 2 }} spacing={4} h="430px" overflow="auto">
            {createdPositions.map((position) => (
              <Card key={position.id} color="white" bg="#132A3A" h="310px" w="220px" fontSize="14px">
                <CardHeader h="4px">
                  <Heading size="sm" fontSize="14px">{(position.name).toString()}</Heading>
                </CardHeader>
                <CardBody>
                  <Text>Total For DCA: {parseInt(position.totalAmountToSwap)}</Text>
                  <Text>Recurrence: {parseInt(position.interval) / 3600} days</Text>
                  <Text>Total Swap From: {parseInt(position.SwappedFromBalance)}</Text>
                  <Text>Total Swap To: {parseInt(position.SwappedToBalance)}</Text>
                  <Text>Amount/Swap: {parseInt(position.amountPerSwap)}</Text>
                  <Text>Last Swap: {getDate(position.lastPurchaseTimestamp._hex)}</Text>
                  <Text>Creation Date: {getDate(position.createdTimestamp._hex)}</Text>
                  <Text color={position.status === 0 ? '#28DA98' : '#ffaf8c'}>Status: {mappings.mappingStatus[position.status]}</Text>
                </CardBody>
                <CardFooter justifyContent="center">
                  <Button backgroundColor={position.status === 0 ? '#28DA98' : position.status === 1 ? '#ffaf8c' : '#28DA98'} color="black" fontWeight="bold" size="sm" onClick={() => handlePause(position.id, position.status)}>
                    {position.status === 0 ? 'Pause' : position.status === 1 ? 'Resume' : ''}
                  </Button>
                  <Button marginLeft={2} backgroundColor="#ffaf8c" color="black" fontWeight="bold" size="sm" onClick={() => handleClose(position.id, position.status)}>
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