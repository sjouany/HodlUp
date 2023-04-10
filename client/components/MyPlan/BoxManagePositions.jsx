import {
  Box, Flex, Button, Text,
  Card, CardHeader, CardBody, CardFooter, SimpleGrid, Heading, useToast
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
  const [isLoadingClose, setIsLoadingClose] = useState(false);
  const [isLoadingPause, setIsLoadingPause] = useState(false);
  const toast = useToast();

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
      return;
    }
    const eventFilter = myContract.filters.PositionCreated(address, null, null);
    if (!eventFilter) {
      return;
    }
    const events = await myContract.queryFilter(eventFilter, 41370855, 'latest');
    if (!eventFilter) {
      return;
    }
    const positions = []; 
    let index = 0;
    for (const event of events) {
      try {
        const position = await myContract.getPosition(index, { from: address });
        console.log(position);
        let stacking_status="Inactive";
        if (position.status == true){
          stacking_status="Active;"
        }
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
          status: position.status,
          stacking: stacking_status
        }
        positions.push(positionToInsert);
        index++; 
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
    setIsLoadingPause(true);
    try{
      const transaction = await myContractToUpdate.setPositionStatus(id, status);
      toast({
        title: "Position status update successfull",
        status: "success",
        duration: 5000,
        isClosable: true,
      });
    }
    catch{
      toast({
        title: "Error during status update",
        description: error.message,
        status: "error",
        duration: 5000,
        isClosable: true,
      });
    }
    finally{
      setIsLoadingPause(false);
    }
  };

  const closePosition = async (id) => {
    setIsLoadingClose(true);
    try{
      const transaction = await myContractToUpdate.closePosition(id);
      toast({
        title: "Position closed successfully",
        status: "success",
        duration: 5000,
        isClosable: true,
      });
    }
    catch{
      toast({
        title: "Error during position closing",
        description: error.message,
        status: "error",
        duration: 5000,
        isClosable: true,
      });
      console.log(error);
    }
    finally{
      setIsLoadingClose(false);
    }
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

  return (

    <Box className="box_management_position" p="5" borderWidth="1px" position="relative">
      <Flex align="baseline" mt={2}>
        <Box overflowX="auto" width="100%" overflowY="hidden">
          <SimpleGrid columns={{ sm: 1, md: 2 }} spacing={4} h="430px" overflow="auto">
            {createdPositions.map((position) => (
              <Card key={position.id} color="white" bg="#132A3A" h="380px" w="220px" fontSize="14px">
                <CardHeader h="4px">
                  <Heading size="sm" fontSize="14px">{(position.name).toString()}</Heading>
                </CardHeader>
                <CardBody>
                  <Text>Total For DCA: {position.totalAmountToSwap}</Text>
                  <Text>Recurrence: {position.interval} days</Text>
                  <Text>Total Swap From: {position.SwappedFromBalance}</Text>
                  <Text>Total Swap To: {position.SwappedToBalance}</Text>
                  <Text>Amount/Swap: {position.amountPerSwap}</Text>
                  <Text>Last Swap: {position.lastPurchaseTimestamp}</Text>
                  <Text>Creation Date: {position.createdTimestamp}</Text>
                  <Text>Stacking: {position.stacking}</Text>
                  <Text color={position.status === 0 ? '#28DA98' : '#ffaf8c'}>Status: {mappings.mappingStatus[position.status]}</Text>
                </CardBody>
                <CardFooter justifyContent="center">
                  <Button isLoading={isLoadingPause} backgroundColor={position.status === 0 ? '#28DA98' : position.status === 1 ? '#ffaf8c' : '#28DA98'} color="black" fontWeight="bold" size="sm" onClick={() => handlePause(position.id, position.status)}>
                    {position.status === 0 ? 'Pause' : position.status === 1 ? 'Resume' : ''}
                  </Button>
                  <Button isLoading={isLoadingClose} marginLeft={2} backgroundColor="#ffaf8c" color="black" fontWeight="bold" size="sm" onClick={() => handleClose(position.id, position.status)}>
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