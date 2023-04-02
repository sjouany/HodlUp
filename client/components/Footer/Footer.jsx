import { Flex, Text } from '@chakra-ui/react';

const Footer = () => {
    return (
        <Flex justifyContent="center" alignItems="center" width="100%" height="10vh" p="2rem">
            <Text>&copy; Alyra {new Date().getFullYear()}</Text>
        </Flex>
    )   
}

export default Footer;