/**
* Factory calss used to generate records mainly for testing purposes. This is helpful for 
* keeping a single source of test data creation so that it is simple to update test data 
* records should required fields on objects change.  Utilizes a psuedo prototypical pattern.
* To Add new prototypes add a new entry to the sObjectMap witht he key being the lowercase
* of the String version of the SObject type of the record and a new instance of the record with
* the defult fields with values that should be filled in
*
* Usage:
* Account a = new Account(industry='Automotive', Name = 'Test');
* List<Account> accts = TestDataFactory.createSObjectRecords(a, 10);
* OR
* List<Contact> contacts = TestDataFactory.createSObjectRecords(new Contact(Lastname='John'), 3);
*/
@isTest
public class TestDataFactory {
    @TestVisible
    private static final Integer NUMBER_OF_TEST_RECORDS = 3;
    
    
	/**
    * Mapping sobjectType to prototype object could probably move to custom setting map or json object
    * so that this could be built without having to change the class another option would be
    * to dynamically decribe object and fill in with a faker class depending on the field type
    */
    @TestVisible
    private static Map<String, SObject> sObjectMap = new Map<String, SObject>{
        'Account' => new Account(Name='Account'),
        //'personaccount' => new Account(LastName='Account', RecordTypeId = Account.getSobjectType().getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId()),
        'Opportunity' => new Opportunity( Name='Opportunity', StageName = 'Prospecting', 
                                            CloseDate = Date.today().addMonths(3)
                                        )
    };
    
     /**
     * Static initialization of map from custom metadata
     */
    static {
        //load defaults from custom metadata
        List< Default_Object_Setting__mdt > defaultDefinitions = [SELECT Object_Name__r.QualifiedApiName , 
                                                                  Object_Definition__c, Override_Code_Definition__c 
                                                                  FROM Default_Object_Setting__mdt];
        for(Default_Object_Setting__mdt setting : defaultDefinitions){
            //Add to map if not defined in code or if set to override
            if(!TestDataFactory.sObjectMap.containsKey(setting.Object_Name__r.QualifiedApiName) || setting.Override_Code_Definition__c){
                try{
            		TestDataFactory.sObjectMap.put(setting.Object_Name__r.QualifiedApiName, (SObject) JSON.deserialize(setting.Object_Definition__c, Type.forName(setting.Object_Name__r.QualifiedApiName)));
                }catch(Exception e){}
            }
        }
    }
    
    /**
     * Check if person accounts is enabled
     */
    @TestVisible
    private static Boolean isPersonAccountEnabled {
        get{
            if(isPersonAccountEnabled == null){
                isPersonAccountEnabled = Schema.sObjectType.Account.fields.getMap().containsKey( 'isPersonAccount' );
            }
            return isPersonAccountEnabled;
        }
        private set;
    }
            

    /**
    * Creates list of records that includes fields that are included in the prototype if the fields do not exists in the base object
    * @param obj The Base object from which the list will be derived
    * @param numberOfRecords The number of records that will be create
    * @param isPersonAccount Flag that is used to determine if the person account prototype should be used instead of the Account prototype
    */
    private static List<SObject> createSobjectRecords(SObject obj, Integer numberOfRecords, Boolean isPersonAccount){
        //if the object is an account and the isPerson account flag is set use special person account prototye
        String sObjectName = isPersonAccount && obj.getSObjectType() == Account.SObjectType ? 'personaccount' : String.valueOf(obj.getSObjectType());
        //todo: maybe handle person accounts differently
        Map<String, Object> objFields = obj.getPopulatedFieldsAsMap();
        //if a prototype exists use it to augment the base record
        if(sObjectMap.containsKey(sObjectName)){
            Map<String, Object> prototypeFields = sObjectMap.get(sObjectName).getPopulatedFieldsAsMap();
            for(String fieldName : prototypeFields.keySet()){
                if(!objFields.containsKey(fieldName)){
                    obj.put(fieldName, prototypeFields.get(fieldName));
                }
            }
        }
        //get the new list of fields
        objFields = obj.getPopulatedFieldsAsMap();
        String listTypeName = String.format('List<{0}>', new List<String>{ String.valueOf(obj.getSObjectType())});
        List<SObject> objects = (List<SObject>) Type.forName(listTypeName).newInstance();
        for(Integer i = 1; i <= numberOfRecords; i++){
            SObject newRecord = obj.clone(false, true, false, false);
            //if the name field exists give a unique name
            if(objFields.containsKey('Name')){
                newRecord.put('Name', String.format('{0} {1}', new String[] { (String) newRecord.get('Name'), String.valueOf(i)}));
            }
            if(objFields.containsKey('Username')){
                newRecord.put('Username', String.format('a{0}{1}{2}', new String[] { String.valueOf(i), String.valueOf(System.currentTimeMillis()), (String) newRecord.get('UserName')}));
            }
                objects.add(newRecord);
        }
        //return the type of SObject
        return objects;
    }

    
    // Could make person account creation more explicit by making createSobjectRecords
    public static List<Account> createPersonAccounts(Account account, Integer numberOfRecords){
        if(!TestDataFactory.isPersonAccountEnabled){
            return null;//todo throw exception
        }
        return TestDataFactory.createSobjectRecords(account, numberOfRecords, true);
    }

    public static List<SObject> createSobjectRecords(SObject obj, Integer numberOfRecords){
        return TestDataFactory.createSobjectRecords(obj, numberOfRecords, false);
    }
    
    @isTest
    private static void loadFromCustomMetadataTest(){
        //Load metadata items
        for(Default_Object_Setting__mdt objSetting : [SELECT Object_Name__r.QualifiedApiName 
                                                   FROM Default_Object_Setting__mdt]){
			System.assert(TestDataFactory.sObjectMap.containsKey(objSetting.Object_Name__r.QualifiedApiName));
        }
    }
    
    @isTest
    private static void personAccountTest(){
        List<Account> accounts = TestDataFactory.createPersonAccounts(new Account(), TestDataFactory.NUMBER_OF_TEST_RECORDS);
        if(TestDataFactory.isPersonAccountEnabled){
            System.assertEquals(TestDataFactory.NUMBER_OF_TEST_RECORDS, accounts.size());
        } else {
            System.assertEquals(null, accounts);
        }
    }
    
    /**
     * Test creating new record with name field w/wo default name
     */
    @isTest
    private static void createSObjectsTest(){
        List<Account> accounts = TestDataFactory.createSobjectRecords(new Account(), TestDataFactory.NUMBER_OF_TEST_RECORDS);
        System.assertEquals(TestDataFactory.NUMBER_OF_TEST_RECORDS, accounts.size());
        for(Integer i = 0; i < TestDataFactory.NUMBER_OF_TEST_RECORDS; i++){
            System.assertEquals(String.format('{0} {1}', new List<String>{(TestDataFactory.sObjectMap.get('Account')).get('Name').toString(), String.valueOf(i + 1)}), accounts[i].Name);
        }
        final String ACCT_NAME = 'Test Account';
        //test with name passed in
        accounts = TestDataFactory.createSobjectRecords(new Account(Name = ACCT_NAME), TestDataFactory.NUMBER_OF_TEST_RECORDS);
        System.assertEquals(TestDataFactory.NUMBER_OF_TEST_RECORDS, accounts.size());
        for(Integer i = 0; i < TestDataFactory.NUMBER_OF_TEST_RECORDS; i++){
            //not equal to predefined name + increment
            System.assertNotEquals(String.format('{0} {1}', new List<String>{(TestDataFactory.sObjectMap.get('Account')).get('Name').toString(), String.valueOf(i + 1)}), accounts[i].Name);
            //equal to name passed in + increment
            System.assertEquals(String.format('{0} {1}', new List<String>{ ACCT_NAME, String.valueOf(i + 1)}), accounts[i].Name);
        }
        //using upsert to test inserting List<SObject>
        upsert accounts;
    }
    
    /**
     * Test creating new record with username field w/wo default name
     */
    @isTest
    private static void createSObjectsUniqueUserNameTest(){
        //
        final String USER_NAME = 'testuser@test.com';
        Set<String> usernames = new Set<String>{USER_NAME};
        User templateUser = new User(Alias = 'standt', Email= 'testuser@test.com', 
                                 EmailEncodingKey='UTF-8', FirstName = 'Test', 
                                 LastName='Testing', LanguageLocaleKey = 'en_US', 
                                 LocaleSidKey ='en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'][0].Id, 
                                 TimeZoneSidKey ='America/Los_Angeles', 
                                 UserName = USER_NAME);
        List<User> users = TestDataFactory.createSobjectRecords(templateUser, TestDataFactory.NUMBER_OF_TEST_RECORDS);
        for(User u : users){
            System.assert(!usernames.contains(u.Username), u.Username);
            usernames.add(u.Username);
        }
        //should be able to insert these records without an issue
        insert users;
    }
}