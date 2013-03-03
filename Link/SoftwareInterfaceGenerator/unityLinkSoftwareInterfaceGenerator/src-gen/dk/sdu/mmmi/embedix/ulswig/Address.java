/**
 */
package dk.sdu.mmmi.embedix.ulswig;

import org.eclipse.emf.common.util.EList;

import org.eclipse.emf.ecore.EObject;

/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Address</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * <ul>
 *   <li>{@link dk.sdu.mmmi.embedix.ulswig.Address#getName <em>Name</em>}</li>
 *   <li>{@link dk.sdu.mmmi.embedix.ulswig.Address#getElements <em>Elements</em>}</li>
 * </ul>
 * </p>
 *
 * @see dk.sdu.mmmi.embedix.ulswig.UlswigPackage#getAddress()
 * @model
 * @generated
 */
public interface Address extends EObject
{
  /**
   * Returns the value of the '<em><b>Name</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <p>
   * If the meaning of the '<em>Name</em>' attribute isn't clear,
   * there really should be more of a description here...
   * </p>
   * <!-- end-user-doc -->
   * @return the value of the '<em>Name</em>' attribute.
   * @see #setName(String)
   * @see dk.sdu.mmmi.embedix.ulswig.UlswigPackage#getAddress_Name()
   * @model
   * @generated
   */
  String getName();

  /**
   * Sets the value of the '{@link dk.sdu.mmmi.embedix.ulswig.Address#getName <em>Name</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the new value of the '<em>Name</em>' attribute.
   * @see #getName()
   * @generated
   */
  void setName(String value);

  /**
   * Returns the value of the '<em><b>Elements</b></em>' attribute list.
   * The list contents are of type {@link java.lang.String}.
   * <!-- begin-user-doc -->
   * <p>
   * If the meaning of the '<em>Elements</em>' attribute list isn't clear,
   * there really should be more of a description here...
   * </p>
   * <!-- end-user-doc -->
   * @return the value of the '<em>Elements</em>' attribute list.
   * @see dk.sdu.mmmi.embedix.ulswig.UlswigPackage#getAddress_Elements()
   * @model unique="false"
   * @generated
   */
  EList<String> getElements();

} // Address
