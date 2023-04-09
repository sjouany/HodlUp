import { } from "@chakra-ui/react";
import {
  Modal,
  ModalOverlay,
  ModalContent,
  ModalHeader,
  ModalFooter,
  ModalBody,
  ModalCloseButton,
  useDisclosure,
  Button,
  useToast,
  FormControl, Input
} from '@chakra-ui/react'
import { useAccount, useProvider, useSigner } from 'wagmi'
import { getNetwork } from '@wagmi/core'
import { useState, useEffect } from 'react'
import { ethers } from 'ethers'
import hodlUpHubfromContract from "../../src/contracts/HodlUpHub.json"
import ERC20Contract from "../../src/contracts/ERC20.json"


function ButtonDCA(props) {
  const [myContract, setMyContract] = useState(null);
  const [myAddress, setMyAddress] = useState("0x");
  const { data: signer } = useSigner();
  const provider = useProvider();
  const [isLoading, setIsLoading] = useState(false);
  const { address, isConnecting, isDisconnected } = useAccount();
  const { isOpen, onOpen, onClose } = useDisclosure();
  const [inputValue, setInputValue] = useState("");
  const toast = useToast();
  const loadContract = async () => {

    const { chain } = getNetwork();
    //const contractAddress = hodlUpHubfromContract.networks[137].address;
    const hodlUpContractAddress = hodlUpHubfromContract.networks[chain.id == 1337 ? 137 : chain.id].address;
    const hodlUpContractABI = hodlUpHubfromContract.abi;
    const hodlUpContract = new ethers.Contract(hodlUpContractAddress, hodlUpContractABI, signer);
    //console.log(signer);
    // Stockez le contrat dans l'état du composant --chain.chainId=
    setMyContract(hodlUpContract);
    setMyAddress(address);
  };

  useEffect(() => {
    loadContract();
  }, [useProvider, signer, useAccount]);


  const createPosition = async () => {
    //props.handleClick();
    const amountValue = (document.getElementById("input-amount").value);
    const tokenTo = (document.getElementById("token-to").value);
    const tokenFrom = (document.getElementById("token-from").value);
    const stake = (document.getElementById("stake").checked);
    const selectedIntervalRadio = document.querySelector('input[name="interval"]:checked');
    const selectedIterationsRadio = document.querySelector('input[name="iterations"]:checked');
    const interval = selectedIntervalRadio.value;
    let iterations;
    console.log("interval :",interval);
    if (selectedIterationsRadio) {
      iterations = selectedIterationsRadio.value;
    } else {
      iterations = 0;
    }
    console.log("Iterations:", iterations);
    console.log("Amount:", amountValue);
    console.log("TokenTo:", tokenTo);
    console.log("Stake:", stake);
    console.log("TokenFrom:", tokenFrom);

    const ERC20ABI = ERC20Contract.abi;
    const tokenFromContractSigner = new ethers.Contract(tokenFrom, ERC20ABI, signer);
    const tokenFromContractProvider = new ethers.Contract(tokenFrom, ERC20ABI, provider);

    // Instance de la structure Pair
    const pair = {
      token_from: tokenFrom, // Adresse ERC20 du token from
      token_to: tokenTo, // Adresse ERC20 du token to
      active: stake
    };

    // Vérifiez si le contrat a été chargé avec succès
    if (!myContract) {
      console.error('Le contrat n\'a pas encore été chargé');
      return;
    }
    setIsLoading(true); // Activer isLoading
    try {
      const decimals = await tokenFromContractProvider.decimals();
      const totalAmountToSwap = (amountValue * (10 ** decimals)).toString();
      const transactionApprove = await tokenFromContractSigner.approve(myContract.address, totalAmountToSwap);
      const transaction = await myContract.createPosition(inputValue, pair, totalAmountToSwap, interval, 0, iterations, stake);

      toast({
        title: "Position crée avec succès",
        status: "success",
        duration: 5000,
        isClosable: true,
      });
    } catch (error) {
      toast({
        title: "Erreur lors de l'ajout d'une position",
        description: error.message,
        status: "error",
        duration: 5000,
        isClosable: true,
      });
      console.log(error);
    } finally {
      setIsLoading(false); // Désactiver isLoading
    }
  };

  const handleInputChange = (event) => {
    setInputValue(event.target.value);
  };

  const handleSubmit = () => {
    onClose();
    createPosition();
  };

  return (
    <>
      <Button
        onClick={onOpen}
        isLoading={isLoading}
        backgroundColor="#28DA98"
        color="black"
        fontWeight="bold"
        size="lg"
        _hover={{ backgroundColor: "#22ba8a" }}
      >
        {props.label}
      </Button>
      <Modal closeOnOverlayClick={false} isOpen={isOpen} onClose={onClose} isCentered backgroundColor="#28DA98">
        <ModalOverlay />
        <ModalContent backgroundColor="#132A3A">
          <ModalHeader color="#28DA98">Choose a name for your position</ModalHeader>
          <ModalCloseButton />
          <ModalBody pb={6}>
          <FormControl>
              <Input color="white" type="text" value={inputValue} onChange={handleInputChange} />
            </FormControl>
          </ModalBody>
          <ModalFooter>
            <Button onClick={handleSubmit} backgroundColor="#28DA98" mr={3}>
              Save
            </Button>
            <Button variant="ghost" backgroundColor="#28DA98" onClick={onClose}>Cancel</Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </>
  );
}

export default ButtonDCA;

