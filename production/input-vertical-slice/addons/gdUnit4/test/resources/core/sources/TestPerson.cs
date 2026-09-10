using Godot;

namespace Example.Test.Resources
{
    public partial class TestPerson
    {

        public TestPerson(string firstName, string lastName)
        {
            FirstName = firstName;
            LastName = lastName;
        }

        public string FirstName { get; }

        public string LastName { get; }

        public string FullName => FirstName + " " + LastName;

        public string FullName2() => FirstName + " " + LastName;

        public string FullName3()
        {
            return FirstName + " " + LastName;
        }

    }
}
